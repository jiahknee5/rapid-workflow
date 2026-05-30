#!/usr/bin/env python3
"""FORGE Observe — lightweight server for the live observability dashboard.

Usage:
    cd <project-root>
    python3 ~/projects/rapid-workflow/tools/observe-server.py [--port 4040]

Serves:
    /                    → dashboard HTML
    /api/events          → merged, sorted JSONL from .forge/observe/*.jsonl
    /api/agents          → current agent summary (latest state per agent)
    /api/meta            → phase, totals, config
"""

import argparse
import json
import os
import glob
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from pathlib import Path
from datetime import datetime, timezone

DASHBOARD_PATH = Path(__file__).parent.parent / "docs" / "observatory.html"
OBSERVE_DIR = ".forge/observe"


def read_all_events(observe_dir, since_seq=0):
    events = []
    pattern = os.path.join(observe_dir, "*.jsonl")
    for filepath in glob.glob(pattern):
        with open(filepath, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    evt = json.loads(line)
                    if evt.get("seq", 0) > since_seq:
                        events.append(evt)
                except json.JSONDecodeError:
                    continue
    events.sort(key=lambda e: (e.get("t", ""), e.get("seq", 0)))
    return events


def get_agent_summary(events):
    agents = {}
    for evt in events:
        aid = evt.get("agent", "unknown")
        if aid not in agents:
            agents[aid] = {
                "agent": aid,
                "role": evt.get("role", ""),
                "status": "active",
                "last_event": evt.get("event", ""),
                "last_detail": evt.get("detail", ""),
                "last_time": evt.get("t", ""),
                "ctx_est": evt.get("ctx_est", 0),
                "task": evt.get("task", ""),
                "phase": evt.get("phase", ""),
                "event_count": 0,
                "reads": 0,
                "writes": 0,
                "sends": 0,
                "loops": 0,
            }
        a = agents[aid]
        a["last_event"] = evt.get("event", a["last_event"])
        a["last_detail"] = evt.get("detail", a["last_detail"])
        a["last_time"] = evt.get("t", a["last_time"])
        a["ctx_est"] = evt.get("ctx_est", a["ctx_est"])
        a["task"] = evt.get("task", a["task"])
        a["phase"] = evt.get("phase", a["phase"])
        a["event_count"] += 1
        ev = evt.get("event", "")
        if ev == "READ":
            a["reads"] += 1
        elif ev == "WRITE":
            a["writes"] += 1
        elif ev == "SEND":
            a["sends"] += 1
        elif ev == "LOOP_ITER":
            a["loops"] += 1
        elif ev == "COMPLETE":
            a["status"] = "complete"
        elif ev == "ERROR":
            a["status"] = "error"
    return list(agents.values())


def get_meta(events, observe_dir):
    phase = ""
    total_ctx = 0
    agent_count = set()
    for evt in events:
        if evt.get("phase"):
            phase = evt["phase"]
        if evt.get("ctx_est"):
            ctx = evt["ctx_est"]
            if isinstance(ctx, str):
                ctx = int(ctx.replace("~", "").replace("K", "000").replace("k", "000"))
            total_ctx = max(total_ctx, ctx)
        agent_count.add(evt.get("agent", ""))
    # Cross-system status (R-12/R-13): eval test gate + docs currency, so the
    # dashboard surfaces test pass/fail and doc freshness alongside the build.
    forge_dir = os.path.dirname(observe_dir) or "."
    root = os.path.dirname(forge_dir) or "."

    def _load(p):
        try:
            with open(p) as f:
                return json.load(f)
        except Exception:
            return None

    exitj = _load(os.path.join(forge_dir, "P6_EXIT.json"))
    eval_status = {"present": exitj is not None, "pass": 0, "fail": 0}
    if exitj is not None:
        asserts = exitj if isinstance(exitj, list) else exitj.get("assertions", [])
        for a in asserts:
            if isinstance(a, dict):
                if a.get("pass") is True:
                    eval_status["pass"] += 1
                elif a.get("pass") is False:
                    eval_status["fail"] += 1

    docsj = _load(os.path.join(root, "docs.json")) or {}
    docs_status = {
        "present": bool(docsj),
        "version": docsj.get("version"),
        "updated": docsj.get("updated"),
        "count": len(docsj.get("docs", [])),
    }

    return {
        "phase": phase,
        "total_events": len(events),
        "active_agents": len(agent_count),
        "ctx_total_est": total_ctx,
        "eval": eval_status,
        "docs": docs_status,
        "observe_dir": observe_dir,
        "server_time": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }


class ObserveHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        qs = parse_qs(parsed.query)

        if path == "/" or path == "/dashboard":
            self.serve_dashboard()
        elif path == "/api/events":
            since = int(qs.get("since", ["0"])[0])
            self.serve_json(self.get_events(since))
        elif path == "/api/agents":
            self.serve_json(self.get_agents())
        elif path == "/api/meta":
            self.serve_json(self.get_meta())
        else:
            self.serve_static(path)

    def serve_dashboard(self):
        if not DASHBOARD_PATH.exists():
            self.send_error(500, f"Dashboard not found at {DASHBOARD_PATH}")
            return
        content = DASHBOARD_PATH.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", len(content))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(content)

    def serve_static(self, path):
        # The dashboard (observatory.html) is served at "/" but lives in docs/,
        # and its nav links to sibling deck pages (prd.html, spec.html, ...) plus
        # documentation.html fetches ../docs.json. Serve ONLY the docs/ tree and
        # the docs.json registry — nothing else in the project is exposed.
        import posixpath
        import mimetypes
        rel = posixpath.normpath(path).lstrip("/")
        if not rel or ".." in rel.split("/"):
            self.send_error(404)
            return
        cwd = os.path.realpath(os.getcwd())
        docs_dir = os.path.realpath(os.path.join(cwd, "docs"))
        if rel == "docs.json":
            fp = os.path.realpath(os.path.join(cwd, "docs.json"))
            allowed = fp == os.path.realpath(os.path.join(cwd, "docs.json"))
        else:
            fp = os.path.realpath(os.path.join(docs_dir, rel))
            allowed = fp == docs_dir or fp.startswith(docs_dir + os.sep)
        if not (allowed and os.path.isfile(fp)):
            self.send_error(404)
            return
        ctype = mimetypes.guess_type(fp)[0] or "application/octet-stream"
        if ctype.startswith("text/") or ctype.endswith(("json", "javascript")):
            ctype += "; charset=utf-8"
        data = open(fp, "rb").read()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", len(data))
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)

    def serve_json(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def get_events(self, since=0):
        observe_dir = os.path.join(os.getcwd(), OBSERVE_DIR)
        if not os.path.isdir(observe_dir):
            return []
        return read_all_events(observe_dir, since)

    def get_agents(self):
        events = self.get_events()
        return get_agent_summary(events)

    def get_meta(self):
        observe_dir = os.path.join(os.getcwd(), OBSERVE_DIR)
        events = self.get_events()
        return get_meta(events, observe_dir)

    def log_message(self, fmt, *args):
        pass


def main():
    parser = argparse.ArgumentParser(description="FORGE Observe dashboard server")
    parser.add_argument("--port", type=int, default=4040, help="Port (default: 4040)")
    args = parser.parse_args()

    observe_dir = os.path.join(os.getcwd(), OBSERVE_DIR)
    os.makedirs(observe_dir, exist_ok=True)

    server = HTTPServer(("127.0.0.1", args.port), ObserveHandler)
    print(f"\033[1;34mFORGE Observe\033[0m → http://localhost:{args.port}")
    print(f"  Watching: {observe_dir}")
    print(f"  Dashboard: {DASHBOARD_PATH}")
    print(f"  Press Ctrl+C to stop\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.server_close()


if __name__ == "__main__":
    main()
