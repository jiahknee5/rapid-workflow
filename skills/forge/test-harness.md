# Forge Test Harness

> Run after any SKILL.md change to verify the 6 fixes still prevent the 5 gaps.
> Invoke: `/forge test` or read this file and execute each check.

## How to use

Each test below has a **Check** (grep/read the SKILL.md) and a **Fail condition** (what it looks like when the fix has regressed). Run all 10 checks after editing SKILL.md. Any failure means the fix was accidentally reverted.

---

## Test 1: Reference project protocol exists

**Gap it prevents:** Agents copy reference code instead of building from spec → missing features that spec requires but reference lacks.

**Check:**
```bash
grep -c "Reference project protocol" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1
**Fail:** 0 — the protocol was removed or renamed. Agents will follow reference code blindly.

**Also verify content:**
```bash
grep -A3 "Reference project protocol" ~/.claude/skills/forge/SKILL.md | grep -c "spec is the authority"
```
**Pass:** Count >= 1

---

## Test 2: Smoke test is mandatory and orchestrator-run

**Gap it prevents:** Orchestrator never runs build/test commands → missing deps, broken imports go undetected.

**Check:**
```bash
grep -c "Smoke test (mandatory, not skippable)" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

**Also verify it says orchestrator runs it:**
```bash
grep -c "orchestrator (not the agent) runs" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

---

## Test 3: Code review is mandatory

**Gap it prevents:** Reviewer never spawned → fabricated outputs, Article I violations go uncaught.

**Check:**
```bash
grep -c "Code review (mandatory, not skippable)" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

**Also verify blocking language:**
```bash
grep -c "Phase 7 cannot begin until every task has a reviewer verdict of APPROVE" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

---

## Test 4: Secret scanning exists

**Gap it prevents:** Real API keys committed to repo via copied .env files.

**Check:**
```bash
grep -c "Secret Scanning" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

**Also verify the grep command is specified:**
```bash
grep -c "api-key.*api_key.*apikey" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

---

## Test 5: Phase 7 requires execution, not file audit

**Gap it prevents:** Orchestrator audits file existence ("tests/meridian.ts exists") instead of running `anchor test`.

**Check:**
```bash
grep -c "not a file audit, not a markdown review" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

**Also verify TEST_RESULTS.md is required:**
```bash
grep -c "TEST_RESULTS.md" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 2 (once in Phase 7, once in State Files table)

---

## Test 6: P6 exit assertions produce proof file

**Gap it prevents:** Orchestrator skips exit assertions entirely — nothing blocks phase advancement.

**Check:**
```bash
grep -c "P6_EXIT.json" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 3 (exit assertion section, enforcement paragraph, state files table)

**Also verify the three new assertions exist:**
```bash
grep -c "reviewer verdict of APPROVE" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 2 (one in step 4, one in exit assertions)

---

## Test 7: Heartbeat protocol exists

**Gap it prevents:** Agents stall silently with no way to detect until 15-minute timeout.

**Check:**
```bash
grep -c "HEARTBEAT.json" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 3

---

## Test 8: claude-peers protocol is mandatory

**Gap it prevents:** Agents don't report status → operator can't monitor build without reading files.

**Check:**
```bash
grep -c "claude-peers Protocol (mandatory" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 1

---

## Test 9: `/forge status` dashboard exists

**Gap it prevents:** Operator has to read 10+ individual files to understand build state.

**Check:**
```bash
grep -c "forge status" ~/.claude/skills/forge/SKILL.md
```
**Pass:** Count >= 3 (invocation, observability section, dashboard section)

---

## Test 10: CHANGELOG.md exists and is current

**Gap it prevents:** Changes to the skill are untraceable — can't tell what version introduced or fixed what.

**Check:**
```bash
test -f ~/.claude/skills/forge/CHANGELOG.md && echo "EXISTS" || echo "MISSING"
```
**Pass:** EXISTS

**Also verify it mentions the Meridian retro:**
```bash
grep -c "Meridian" ~/.claude/skills/forge/CHANGELOG.md
```
**Pass:** Count >= 1

---

## Run all tests at once

```bash
echo "=== FORGE SKILL TEST HARNESS ===" && \
echo "" && \
echo "T1 Reference protocol: $(grep -c 'Reference project protocol' ~/.claude/skills/forge/SKILL.md) (need >=1)" && \
echo "T2 Smoke test mandatory: $(grep -c 'Smoke test (mandatory' ~/.claude/skills/forge/SKILL.md) (need >=1)" && \
echo "T3 Review mandatory: $(grep -c 'Code review (mandatory' ~/.claude/skills/forge/SKILL.md) (need >=1)" && \
echo "T4 Secret scanning: $(grep -c 'Secret Scanning' ~/.claude/skills/forge/SKILL.md) (need >=1)" && \
echo "T5 Execute not audit: $(grep -c 'not a file audit' ~/.claude/skills/forge/SKILL.md) (need >=1)" && \
echo "T6 P6_EXIT proof: $(grep -c 'P6_EXIT.json' ~/.claude/skills/forge/SKILL.md) (need >=3)" && \
echo "T7 Heartbeat: $(grep -c 'HEARTBEAT.json' ~/.claude/skills/forge/SKILL.md) (need >=3)" && \
echo "T8 Peers mandatory: $(grep -c 'claude-peers Protocol' ~/.claude/skills/forge/SKILL.md) (need >=1)" && \
echo "T9 Status dashboard: $(grep -c 'forge status' ~/.claude/skills/forge/SKILL.md) (need >=3)" && \
echo "T10 Changelog: $(test -f ~/.claude/skills/forge/CHANGELOG.md && echo 'EXISTS' || echo 'MISSING')" && \
echo "" && \
echo "=== DONE ==="
```
