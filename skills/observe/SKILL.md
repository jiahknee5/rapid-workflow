---
name: observe
description: >
  Build a project-tailored **Observatory** — the live, watchable view of an autonomous
  Rapid build. When applied to a project it INSPECTS that project (its agent roster,
  its phases, its workflow, its acceptance signals) and GENERATES the dashboard,
  the event-logging contract, and the polling wiring specific to it — not a copied
  generic shell. The deterministic spine (one append-only JSONL stream per role with a
  monotonic seq, a merge/serve server, incremental polling-since-seq) never changes;
  the topology, the health signals, and the phase ribbon are composed from the project.
  Observability is the TRUST MECHANISM for hands-off autonomy: once the operator hands
  over the keys at Gate 2, the only way to trust the build is to watch it. Use at P1
  (scaffold), P6 (feed), P9 (deploy). Triggers: "build the observatory", "wire up
  observability for this project", "make the build watchable", "/observe".
---

# /observe — the Dynamic Observability Builder

> Plain English: this builds the window into an autonomous build. You point it at a
> project and it generates a dashboard tailored to *that* project's agents and phases,
> plus the plumbing that keeps the dashboard live without anyone remembering to update it.
>
> **Technically:** it derives a per-project Observatory (topology + health + event
> stream) from `.rapid/` + `04-spec/agents/`, emits `docs/observatory.html` and its
> data contract, and wires the logging→server→poll loop. The data contract is fixed;
> the surface is generated.

## When to use

- **P1 — Scaffold.** Stand up the Observatory for a new project *before* the build runs, so the first `SPAWN` already has somewhere to land.
- **P6 — Feed.** During the build the surface is live; re-run `/observe` if the agent roster or phase set changed (e.g. a track switch) so the topology stays honest.
- **P9 — Deploy.** Ship the Observatory next to the product at `/_atlas` so the build remains auditable after the fact.
- Standalone, on any agentic system that emits the event contract — the Observatory is product-agnostic.

## Core thesis — watchable, or it isn't trustworthy

When one agent both builds and audits, visible progress beats invisible safety — so Rapid separates those roles. But a *separated* autonomous build is still a black box unless you can see inside it. **Observability is the structural answer to "how do I trust what I can't watch": you make it watchable.** Three properties make the watching trustworthy rather than theatrical:

1. **Mechanical, not voluntary.** Logging is emitted by **hooks** as a side-effect of every Write/Edit/Stop — an agent that *forgets* to log is still logged. A surface that depends on agents choosing to report is a surface that goes dark exactly when something is going wrong.
2. **Append-only + monotonic.** One JSONL line per event, a `seq` that only increases, never truncated mid-run. The timeline is a ledger, not a mutable status board — you can replay it, and a crash loses nothing already written.
3. **Honest degradation.** When the server is down the dashboard says "no build running" — it never pretends. A green light that can't go red is decoration.

## Fixed vs. dynamic — what the skill must NOT reinvent, and what it composes

| Layer | **Fixed** (the deterministic spine — identical every project) | **Dynamic** (composed from THIS project) |
|---|---|---|
| Event stream | One append-only JSONL line per event to `.rapid/observe/<role>.jsonl`; monotonic `seq` from `.rapid/observe/seq.txt` (pre-increment); the fixed vocabulary below | Which `<role>` files exist (the project's agent roster) |
| Vocabulary | `SPAWN · PHASE · GATE · READ · WRITE · TOOL · SEND · RECV · DECIDE · ESCALATE · LOOP_START · LOOP_ITER · LOOP_END · STOP · CONTEXT · COMPLETE · ERROR` — plus the enforcement-hook events `STUB · CONFORMANCE` (emitted by `stub-detect-hook.sh` / `module-conformance-hook.sh`) | — (the core set is closed; agents do not invent event types — enforcement hooks own the two extras) |
| Server | `tools/observe-server.py` merges + sorts the per-role JSONL and serves `/api/events?since=<seq>`, `/api/agents`, `/api/meta` | The port (default `:4040`); `env.json` `local.url` + `launch` |
| Refresh | Dashboard polls `/api/events?since=<lastSeq>` (~2s, incremental — only events after the last rendered seq) | The poll interval if the project needs it tuned |
| Hooks | PostToolUse/Stop hooks auto-emit observe events (R1/R7/R8/R9 + post-write) | Which hook set the project installs |
| **Topology** | — | The **agent roster + how it nests** (leads → the subagents they fan out), read from `04-spec/agents/` + live `SPAWN` events |
| **Health** | The `/api/meta` schema (phase, totals, active agents, ctx, eval, docs) | Which signals matter for THIS project + their thresholds (heartbeat staleness, cost ceiling, stall window) |
| **Phase ribbon** | — | THIS project's phase list and the gate positions |

The rule: **never reimplement the spine; always regenerate the surface.** A project with three agents and a six-node workflow gets a three-lane topology and a six-step ribbon — not the kit's demo five-lane view.

## The event contract (the one source the whole surface derives from)

Every lead, subagent, and hook appends exactly one JSON object per line:

```json
{"t":"<ISO-8601>","seq":<int>,"agent":"<id>","role":"<role>","event":"<VOCAB>","detail":"<short>","phase":"<Pn>","task":"<task-id|>","ctx_est":<int>,"ctx_total":<int>}
```

- `seq` is read-then-incremented from `.rapid/observe/seq.txt` so the merged stream has a total order across roles.
- `role` comes from `RAPID_ROLE`, exported per terminal when the team is stood up — that's how the server attributes events without the agent self-declaring each time.
- Subagents carry the parent's role family in `agent` (e.g. `coder-1`) so the topology can nest them under the lead that fanned them out. Build-writer `SPAWN`s additionally carry `worktree`/`branch` (the isolation proof the watchdog checks).
- Append-only is the contract. Truncating mid-run is a P0 violation — the ledger must survive a crash.

## Construction protocol — the skill's core loop (this is what "builds itself" means)

**1. Inspect the project.** Read, do not assume:
- `04-spec/agents/*.md` → the agent roster and each role's job (the leads). Note which leads fan out subagents (the coder's worktree writers, the reviewer's per-dimension subagents, the tester's per-surface subagents).
- `.rapid/STATE.json` → the phase list and current phase; `.rapid/TASKS.json` → the task graph; `.rapid/EVAL/` + `P6_EXIT.json` → the eval signals; `.rapid/COST.json` → the budget + ceiling; `04-spec/workflow.md` → the user-journey nodes the health view counts against.
- `env.json` → the local launch command + the deployed/source links the header shows.

**2. Derive the topology + the health signals for THIS project.** Produce a small manifest (`.rapid/observe/topology.json`): the ordered role lanes (lead → its subagent ids), the phase ribbon, and the health signals that matter here (e.g. tests-passing if there's an eval harness, cost vs ceiling if there's a budget, doc-staleness if there's an Atlas, heartbeat/stall windows). A non-UI batch job and a 12-phase web build get *different* health views — derive, don't hardcode.

**3. Generate the tailored surface.** Fill the Observatory template from the manifest — the topology lanes, the phase ribbon, the L1 event-filter tabs (one per lead role + a Subagents bucket + All), and the health panel — so the rendered `docs/observatory.html` reflects this project's roles and phases. Keep the deterministic JS spine (poll-since-seq, the agent-color map keyed by the project's roles, honest "no build running" empty state). The surface is generated *from* the roster, so adding a role can't leave the dashboard showing a stale lane.

**4. Wire the loop.** Confirm the three families are connected: (a) **logging** — every role writes to its `.rapid/observe/<role>.jsonl`, seq pre-incremented; (b) **hooks auto-emit** — the PostToolUse/Stop hooks append observe events mechanically; (c) **polling** — the dashboard requests `/api/events?since=<lastSeq>`. Register the server launch in `env.json` (`local.launch`) so the operator can bring it up with one line.

**5. Verify (acceptance — see below).** Drive a sample stream (or the live build) and confirm: every role in the roster appears as a lane; the phase ribbon advances with `PHASE` events; the health panel reads real `/api/meta`; and with the server stopped the dashboard degrades to "no build running" with no console errors.

## Health signals — derived, not assumed

`tools/observe-server.py`'s `/api/meta` already exposes the spine: `phase`, `total_events`, `active_agents`, `ctx_total_est`, `eval{present,pass,fail}` (from `P6_EXIT.json`), `docs{present,version,updated,count}` (from the registry). The skill decides **which of these the project's health panel surfaces and at what thresholds**, and adds project-specific derived signals on top (heartbeat staleness → STALLED; `COST.json ≥ ceiling` → OVER BUDGET; drift in `AUDIT.json` → DRIFTED; blocked-on-input → BLOCKED). The health view is a reading of the project's own gates — not a fixed widget set.

## Output contract

- `docs/observatory.html` — the generated, project-tailored dashboard (dark theme, unified header via the same destinations as `rapid-nav.js` / the Atlas top nav).
- `.rapid/observe/topology.json` — the derived manifest the surface is generated from (roster lanes, phase ribbon, health signals). Re-deriving this is how the surface stays current.
- `.rapid/observe/seq.txt` + `.rapid/observe/<role>.jsonl` — the stream (created empty at P1; fed at P6).
- `env.json` `local` block wired with the server launch command.
- A line in `MEMORY.md`: `[ts] /observe — Observatory generated for <N> roles, <M> phases`.

## Verification & acceptance (the watchdog for this skill)

- **Every role is visible.** Each role in `04-spec/agents/` appears as a topology lane and an event-filter tab. A role that builds but isn't watchable fails this skill.
- **The timeline is total-ordered and gap-free.** `seq` is strictly increasing across the merged stream; no truncation. (A regression here means a lost or reordered event.)
- **Hooks actually emit.** Trigger a Write and confirm an observe event lands without the agent explicitly logging it — the mechanical guarantee, tested, not assumed.
- **Honest empty state.** Stop the server; the dashboard renders "no build running", not a stale green board, with zero console errors.
- **Tailored, not copied.** The rendered topology/ribbon/tabs match THIS project's roster and phases — diff against the kit's demo to prove it isn't the generic shell.

## Anti-patterns

- **Copying the kit's `observatory.html` and calling it done.** That's the static shell this skill replaces — the surface must be generated from the project's roster, or a new role silently disappears.
- **Inventing event types.** The vocabulary is closed; a one-off event type can't be filtered, colored, or counted.
- **Voluntary logging.** If the surface depends on agents choosing to report (no hooks), it goes dark under pressure — defeating the purpose.
- **A status board that can't go red.** Health signals with no failing state are decoration; every signal needs an honest bad value.
- **Mutable timeline.** Editing or truncating `.jsonl` to "clean up" — the ledger is append-only.

## Relationship to Rapid & lineage

Pairs with **[[test-theater]]** (the runnable-tests surface) — together they are the two halves of "watch the build, then prove it works." Both share the same JSONL/seq/poll-since-seq plumbing and the same unified header; keep them in lockstep. Feeds the orchestrator's `/rapid-workflow status` (same `.rapid/` reads). Lineage: the event-ledger + poll-since-seq design is closer to an append-only log (Kafka-style offsets) than a mutable dashboard; the "hooks make it mechanical" principle is the same writer-≠-auditor thesis applied to *reporting* — don't let the thing being measured decide whether it's measured.
