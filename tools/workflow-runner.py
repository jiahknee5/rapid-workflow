#!/usr/bin/env python3
"""RAPID Workflow Runner — live-drive a user workflow as an executable test.

Reads docs/workflows.json, runs one workflow's nodes in sequence against the
LIVE build, and streams a node-by-node trace to .rapid/RUNS/<wf>/<run-id>.jsonl
(tailable while it runs — that is the "real-time" feed the testsuite page reads).
Each node threads its data-out into the next node's data-in, so the trace shows
the inputs and outputs at every node end-to-end. On completion it appends a row
to .rapid/RUNS/<wf>/index.json and republishes docs/testruns.json (the static
snapshot the page replays when no server is running).

Usage:
    python3 tools/workflow-runner.py --wf WF-1 [--preset math-tutor]
    python3 tools/workflow-runner.py --wf WF-1 --input '{"idea":"build X"}'
    python3 tools/workflow-runner.py --all          # run every workflow once
    python3 tools/workflow-runner.py --publish-only  # just rebuild testruns.json

Design note: bounded by construction. The `cmd` execs in workflows.json for this
project are the real (seconds-scale) RAPID tools (ship-gate, stub-scan); no node
runs a `/rapid-workflow` build or spends money. For a built project, P5 generates the
node execs to point at that project's own test/e2e commands.
"""

import argparse
import glob as globmod
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKFLOWS_PATH = os.path.join(ROOT, "docs", "workflows.json")
RUNS_DIR = os.path.join(ROOT, ".rapid", "RUNS")
TESTRUNS_PATH = os.path.join(ROOT, "docs", "testruns.json")
PUBLISH_LIMIT = 25            # max runs kept per workflow in testruns.json
CMD_TIMEOUT = 180             # hard ceiling on any single node command (s)
CODEX_TIMEOUT = 300           # ceiling on a codex-agent node (model latency) (s)

# ---- Agent-backed nodes (codex tester + simulated-operator) ----------------
# Two roles, one engine (`codex exec`). The guardrails live in (a) these personas,
# (b) the JSON output schemas, (c) the read-only/sandboxed exec, and (d) the
# deterministic `fallback` each node keeps so the run still completes with no codex.
# Full role docs: 04-spec/agents/tester-codex.md and 04-spec/agents/operator-sim.md.

CODEX_TESTER_PERSONA = (
    "You are the TESTER for an autonomous build. You verify behavior; you never write product code "
    "and you never weaken a test to get a pass. Decide PASS only from evidence you actually observed "
    "(a command you ran with an exit code, or a file you read) — never from assumption. If you cannot "
    "verify, return fail with the reason. You are independent of whoever wrote the code: the writer is "
    "never the auditor."
)
TESTER_SCHEMA = {
    "type": "object", "additionalProperties": False,
    "properties": {
        "status": {"type": "string", "enum": ["pass", "fail"]},
        "evidence": {"type": "string", "description": "what you observed that justifies the verdict"},
        "commands_run": {"type": "array", "items": {"type": "string"}},
    },
    # OpenAI strict structured outputs require EVERY property in `required`.
    "required": ["status", "evidence", "commands_run"],
}

OPERATOR_SIM_PERSONA = (
    "You are a SIMULATED OPERATOR — a stand-in for the human decision-maker at a RAPID gate, used ONLY "
    "to dry-run / test the workflow. You are NOT a real human and must never be treated as approval for a "
    "real irreversible action. GUARDRAILS, in order of priority:\n"
    "1. FAIL-SAFE DEFAULT: if the evidence is insufficient, ambiguous, or you are unsure — return decision "
    "\"hold\". Never rubber-stamp. \"approve\" requires concrete cited evidence that the gate's criteria are met.\n"
    "2. NEVER approve anything destructive, irreversible, outward-facing, that spends money, or that deploys/"
    "publishes. For any such gate, set needs_real_human=true and decision=\"hold\" — a real human must own it.\n"
    "3. EVIDENCE ONLY: base the decision solely on the run data and files cited to you; do not invent facts.\n"
    "4. READ-ONLY: you do not modify anything; you only decide.\n"
    "Every decision must carry a rationale and the evidence you relied on."
)
OPERATOR_SCHEMA = {
    "type": "object", "additionalProperties": False,
    "properties": {
        "decision": {"type": "string", "enum": ["approve", "reject", "hold"]},
        "rationale": {"type": "string"},
        "evidence_cited": {"type": "string"},
        "needs_real_human": {"type": "boolean",
                             "description": "true if this gate is destructive/irreversible/outward-facing/spends-money/deploys"},
    },
    # OpenAI strict structured outputs require EVERY property in `required`.
    "required": ["decision", "rationale", "evidence_cited", "needs_real_human"],
}


def _codex_available():
    return shutil.which("codex") is not None


def _run_codex(persona, schema, instruction, node, data_in, spec):
    """Invoke `codex exec` with a guardrailed persona + JSON output schema. Returns
    the parsed verdict dict, or raises on any failure (caller handles fallback)."""
    context = (
        "WORKFLOW NODE: " + node.get("label", "") + "\n"
        "Declared contract — in: " + node.get("in", "") + " | proc: " + node.get("proc", "") +
        " | out: " + node.get("out", "") + "\n"
        "DATA IN (this node's input, the previous node's output):\n" + json.dumps(data_in)[:2000] + "\n\n"
        "INSTRUCTION: " + instruction + "\n\n"
        "Respond ONLY with JSON matching the provided output schema."
    )
    prompt = persona + "\n\n" + context
    sandbox = spec.get("sandbox", "read-only")
    with tempfile.TemporaryDirectory() as td:
        schema_f = os.path.join(td, "schema.json")
        last_f = os.path.join(td, "last.json")
        with open(schema_f, "w") as f:
            json.dump(schema, f)
        cmd = ["codex", "exec", "-s", sandbox, "--skip-git-repo-check", "--color", "never",
               "--output-schema", schema_f, "-o", last_f]
        # extra writable dirs (e.g. a project created outside the kit workspace), so a
        # workspace-write tester can actually run a build that writes there.
        for d in spec.get("add_dir", []):
            cmd += ["--add-dir", os.path.expanduser(d)]
        if spec.get("model"):
            cmd += ["-m", spec["model"]]
        cmd += [prompt]
        # stdin MUST be closed — otherwise `codex exec` tries to read additional input
        # from the inherited stdin ("Reading additional input from stdin…") and fails.
        proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                              stdin=subprocess.DEVNULL, timeout=CODEX_TIMEOUT)
        raw = ""
        if os.path.isfile(last_f):
            raw = open(last_f, encoding="utf-8", errors="replace").read().strip()
        if not raw:
            raw = proc.stdout.strip()
        # the last message may be fenced or have surrounding prose — extract the JSON object
        verdict = _parse_json_blob(raw)
        if verdict is None:
            raise ValueError("codex returned no parseable JSON verdict (exit %s)" % proc.returncode)
        verdict["_engine"] = "codex" + (":" + spec["model"] if spec.get("model") else "")
        verdict["_sandbox"] = sandbox
        return verdict


def _parse_json_blob(s):
    if not s:
        return None
    try:
        return json.loads(s)
    except Exception:
        pass
    i, j = s.find("{"), s.rfind("}")
    if i != -1 and j != -1 and j > i:
        try:
            return json.loads(s[i:j + 1])
        except Exception:
            return None
    return None


def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def load_workflows():
    with open(WORKFLOWS_PATH) as f:
        return json.load(f)


def find_workflow(doc, wf_id):
    for wf in doc.get("workflows", []):
        if wf.get("id") == wf_id:
            return wf
    return None


def _extract(obj, dotted):
    """Resolve a dotted key path. `$len` returns the length of a list/dict/str."""
    cur = obj
    if not dotted:
        return cur
    for part in dotted.split("."):
        if part == "$len":
            return len(cur) if cur is not None else None
        if isinstance(cur, dict):
            cur = cur.get(part)
        elif isinstance(cur, list) and part.isdigit():
            cur = cur[int(part)] if int(part) < len(cur) else None
        else:
            return None
    return cur


def _read_json_file(path):
    fp = path if os.path.isabs(path) else os.path.join(ROOT, path)
    with open(fp) as f:
        return json.load(f)


def _exec_agent(kind, node, spec, data_in, agents):
    """codex tester / simulated-operator node. Honors the agents mode and degrades
    to the node's deterministic `fallback` when codex is off or unavailable."""
    use_codex = agents == "on" or (agents == "auto" and _codex_available())

    def _fallback(reason):
        fb = spec.get("fallback")
        if fb:
            st, out = exec_node({**node, "exec": fb}, data_in, agents="off")
            wrap = {"role": kind, "engine": "fallback (" + reason + ")"}
            wrap.update(out if isinstance(out, dict) else {"out": out})
            return st, wrap
        # no fallback: a human gate with no determinstic check is informational, not a failure
        return ("fail" if kind == "codex" else "info"), {
            "role": kind, "engine": "none", "note": "no fallback (" + reason + ")",
            "declared": node.get("proc", "")}

    if not use_codex:
        return _fallback("agents=" + agents + ("" if _codex_available() else ", codex unavailable"))

    try:
        if kind == "codex":
            v = _run_codex(CODEX_TESTER_PERSONA, TESTER_SCHEMA,
                           spec.get("instruction", "Verify this node passes its declared output."),
                           node, data_in, spec)
            status = "pass" if v.get("status") == "pass" else "fail"
            return status, {"role": "tester", "engine": v.get("_engine", "codex"), "verdict": v}
        # kind == "human" → simulated operator
        v = _run_codex(OPERATOR_SIM_PERSONA, OPERATOR_SCHEMA,
                       spec.get("instruction", spec.get("gate", "Decide on this gate.")),
                       node, data_in, spec)
        v["_simulated"] = True
        dec = v.get("decision")
        # approve→pass, reject→fail, hold→info (needs a real human / more evidence)
        status = "pass" if dec == "approve" else ("fail" if dec == "reject" else "info")
        return status, {"role": "operator (simulated)", "engine": v.get("_engine", "codex"),
                        "gate": spec.get("gate", ""), "verdict": v}
    except subprocess.TimeoutExpired:
        return _fallback("codex timed out after %ss" % CODEX_TIMEOUT)
    except Exception as e:
        return _fallback("codex error: %s: %s" % (type(e).__name__, e))


def exec_node(node, data_in, agents="auto"):
    """Run a node's `exec` against live state. Returns (status, data_out).

    status ∈ {"pass","fail","info"}. data_out is JSON-serializable and becomes
    the next node's data_in, so the trace reads end-to-end. `agents` ∈
    {"auto","on","off"} controls whether codex/human nodes use the live agent.
    """
    spec = node.get("exec") or {"kind": "note"}
    kind = spec.get("kind", "note")

    if kind in ("codex", "human"):
        return _exec_agent(kind, node, spec, data_in, agents)

    try:
        if kind == "note":
            return "info", {"note": spec.get("text", node.get("proc", ""))}

        if kind == "file":
            path = spec["path"]
            fp = path if os.path.isabs(path) else os.path.join(ROOT, path)
            mode = spec.get("mode", "exists")
            exists = os.path.isfile(fp)
            if mode == "exists":
                return ("pass" if exists else "fail"), {"path": path, "exists": exists}
            if not exists:
                return "fail", {"path": path, "exists": False}
            if mode == "lines":
                with open(fp, encoding="utf-8", errors="replace") as f:
                    n = sum(1 for _ in f)
                return "pass", {"path": path, "lines": n}
            if mode == "grep":
                import re
                pat = re.compile(spec.get("pattern", ".*"))
                with open(fp, encoding="utf-8", errors="replace") as f:
                    n = sum(1 for ln in f if pat.search(ln))
                return ("pass" if n > 0 else "fail"), {"path": path, "matches": n, "pattern": spec.get("pattern")}
            return "fail", {"path": path, "error": f"unknown file mode {mode}"}

        if kind == "glob":
            pattern = spec["pattern"]
            full = pattern if os.path.isabs(pattern) else os.path.join(ROOT, pattern)
            matches = globmod.glob(full)
            return ("pass" if matches else "fail"), {"pattern": pattern, "count": len(matches),
                                                     "sample": [os.path.basename(m) for m in matches[:6]]}

        if kind == "read_json":
            obj = _read_json_file(spec["path"])
            val = _extract(obj, spec.get("extract", ""))
            return ("pass" if val is not None else "fail"), {"path": spec["path"], "extract": spec.get("extract"), "value": val}

        if kind == "cmd":
            run = spec["run"]
            expect = spec.get("expect_exit", 0)
            t0 = time.time()
            proc = subprocess.run(["bash", "-lc", run], cwd=ROOT, capture_output=True,
                                  text=True, timeout=CMD_TIMEOUT)
            dt = round(time.time() - t0, 2)
            tail_n = spec.get("tail", 12)
            out_lines = (proc.stdout + proc.stderr).strip().splitlines()
            tail = "\n".join(out_lines[-tail_n:])
            out = {"cmd": run, "exit": proc.returncode, "expect_exit": expect,
                   "elapsed_s": dt, "tail": tail}
            if spec.get("then_read"):
                tr = spec["then_read"]
                try:
                    obj = _read_json_file(tr["path"])
                    out["parsed"] = _extract(obj, tr.get("extract", ""))
                except Exception as e:
                    out["parsed_error"] = str(e)
            status = "pass" if proc.returncode == expect else "fail"
            return status, out

        return "fail", {"error": f"unknown exec kind {kind}"}
    except subprocess.TimeoutExpired:
        return "fail", {"error": f"command timed out after {CMD_TIMEOUT}s"}
    except FileNotFoundError as e:
        return "fail", {"error": f"not found: {e.filename}"}
    except Exception as e:  # surface the real error into the trace, never swallow it
        return "fail", {"error": f"{type(e).__name__}: {e}"}


def run_workflow(doc, wf, input_value, on_event, run_id, agents="auto"):
    """Execute every node; emit events via on_event(dict). Returns the run summary."""
    started = now_iso()
    nodes = wf.get("nodes", [])

    on_event({"seq": 0, "type": "run_start", "wf": wf["id"], "run_id": run_id,
              "t": started, "title": wf.get("title", ""), "input": input_value,
              "golden": wf.get("golden", ""), "node_count": len(nodes), "agents": agents})

    seq = 1
    data_in = input_value
    trace = []
    passed = failed = info = 0
    for i, node in enumerate(nodes):
        on_event({"seq": seq, "type": "node_start", "wf": wf["id"], "run_id": run_id,
                  "t": now_iso(), "node_id": node["id"], "label": node.get("label", ""),
                  "index": i, "data_in": data_in,
                  "declared": {"in": node.get("in", ""), "proc": node.get("proc", ""),
                               "out": node.get("out", "")}}); seq += 1

        t0 = time.time()
        status, data_out = exec_node(node, data_in, agents)
        dt = round(time.time() - t0, 2)

        required = node.get("required", True)
        if status == "pass":
            passed += 1
        elif status == "info":
            info += 1
        else:
            if required:
                failed += 1

        rec = {"node_id": node["id"], "label": node.get("label", ""), "lane": node.get("lane", "system"),
               "node_class": node.get("node_class", "n-auto"), "index": i, "status": status,
               "required": required, "elapsed_s": dt, "view": node.get("view", {"kind": "data"}),
               "declared": {"in": node.get("in", ""), "proc": node.get("proc", ""), "out": node.get("out", "")},
               "data_in": data_in, "data_out": data_out}
        trace.append(rec)

        on_event({"seq": seq, "type": "node_done", "wf": wf["id"], "run_id": run_id,
                  "t": now_iso(), **rec}); seq += 1

        data_in = data_out  # thread output → next input

    overall = "pass" if failed == 0 else "fail"
    summary = {"run_id": run_id, "wf": wf["id"], "title": wf.get("title", ""),
               "started": started, "finished": now_iso(),
               "status": overall, "pass": passed, "fail": failed, "info": info,
               "total": len(nodes), "golden": wf.get("golden", ""),
               "input": input_value, "trace": trace}

    on_event({"seq": seq, "type": "run_done", "wf": wf["id"], "run_id": run_id,
              "t": now_iso(), "status": overall, "pass": passed, "fail": failed,
              "info": info, "total": len(nodes)})
    return summary


def _stream_writer(wf_id, run_id):
    """Return an on_event callback that appends JSONL to the run's live file."""
    d = os.path.join(RUNS_DIR, wf_id)
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, run_id + ".jsonl")
    f = open(path, "a", encoding="utf-8")

    def on_event(evt):
        f.write(json.dumps(evt) + "\n")
        f.flush()
    return on_event, path, f


def append_index(summary):
    d = os.path.join(RUNS_DIR, summary["wf"])
    os.makedirs(d, exist_ok=True)
    idx_path = os.path.join(d, "index.json")
    try:
        idx = json.load(open(idx_path))
    except Exception:
        idx = []
    # store the run summary WITHOUT the full trace in the index (trace lives in the jsonl)
    row = {k: v for k, v in summary.items() if k != "trace"}
    idx.insert(0, row)
    json.dump(idx[:200], open(idx_path, "w"), indent=2)


def publish_testruns():
    """Rebuild docs/testruns.json from every .rapid/RUNS/<wf>/index.json + latest trace."""
    doc = load_workflows()
    out = {"generated": now_iso(), "generated_by": "tools/workflow-runner.py",
           "note": "Published run log + latest full trace per workflow. The testsuite page "
                   "replays this when observe-server is not running (static /_atlas deploy); "
                   "when the server is up it live-tails .rapid/RUNS/<wf>/<run>.jsonl instead.",
           "workflows": {}}
    for wf in doc.get("workflows", []):
        wf_id = wf["id"]
        d = os.path.join(RUNS_DIR, wf_id)
        idx_path = os.path.join(d, "index.json")
        runs = []
        try:
            runs = json.load(open(idx_path))
        except Exception:
            runs = []
        latest_trace = None
        if runs:
            latest_id = runs[0]["run_id"]
            jl = os.path.join(d, latest_id + ".jsonl")
            try:
                trace = []
                summ = None
                for line in open(jl):
                    evt = json.loads(line)
                    if evt.get("type") == "node_done":
                        trace.append(evt)
                    elif evt.get("type") == "run_done":
                        summ = evt
                latest_trace = {"run_id": latest_id, "summary": summ, "nodes": trace}
            except Exception:
                latest_trace = None
        out["workflows"][wf_id] = {
            "runs": [{k: v for k, v in r.items() if k != "trace"} for r in runs[:PUBLISH_LIMIT]],
            "latest": latest_trace,
        }
    json.dump(out, open(TESTRUNS_PATH, "w"), indent=2)
    return TESTRUNS_PATH


def run_one(doc, wf_id, input_value, run_id=None, agents="auto"):
    wf = find_workflow(doc, wf_id)
    if not wf:
        print(f"  ! no workflow {wf_id} in {WORKFLOWS_PATH}", file=sys.stderr)
        return None
    if not run_id:
        run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    on_event, path, f = _stream_writer(wf_id, run_id)
    try:
        summary = run_workflow(doc, wf, input_value, on_event, run_id, agents)
    finally:
        if not f.closed:
            f.close()
    append_index(summary)
    print(f"  {wf_id}: {summary['status'].upper()}  "
          f"{summary['pass']}/{summary['total']} pass, {summary['fail']} fail  → run {summary['run_id']}")
    return summary


def resolve_input(wf, preset_id, raw_input):
    if raw_input:
        return json.loads(raw_input)
    presets = wf.get("presets", [])
    if preset_id:
        for p in presets:
            if p.get("id") == preset_id:
                return p.get("input", {})
        raise SystemExit(f"preset {preset_id} not found for {wf['id']}")
    return presets[0].get("input", {}) if presets else {}


def main():
    ap = argparse.ArgumentParser(description="RAPID workflow runner — live-drive a workflow as a test")
    ap.add_argument("--wf", help="workflow id (e.g. WF-1)")
    ap.add_argument("--preset", help="preset id from workflows.json")
    ap.add_argument("--input", help="raw JSON input (overrides --preset)")
    ap.add_argument("--run-id", help="caller-supplied run id (the server passes this so it can live-tail)")
    ap.add_argument("--agents", choices=["auto", "on", "off"], default="auto",
                    help="codex tester + simulated-operator nodes: on=use codex, off=deterministic fallback, "
                         "auto=codex if available (default). ▶ Run uses auto; bulk --all republish uses off.")
    ap.add_argument("--all", action="store_true", help="run every workflow once")
    ap.add_argument("--publish-only", action="store_true", help="only rebuild docs/testruns.json")
    args = ap.parse_args()

    if args.publish_only:
        print("published", publish_testruns())
        return

    doc = load_workflows()
    if args.all:
        for wf in doc.get("workflows", []):
            run_one(doc, wf["id"], resolve_input(wf, None, None), agents=args.agents)
    elif args.wf:
        wf = find_workflow(doc, args.wf)
        if not wf:
            raise SystemExit(f"no workflow {args.wf}")
        run_one(doc, args.wf, resolve_input(wf, args.preset, args.input), args.run_id, args.agents)
    else:
        raise SystemExit("specify --wf <id>, --all, or --publish-only")

    print("published", publish_testruns())


if __name__ == "__main__":
    main()
