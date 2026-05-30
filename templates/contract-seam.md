<!--
  FORGE TEMPLATE — Seam Contract
  One file per shared seam. Lives in 04-spec/contracts/.

  WHY THIS EXISTS (the biggest reference-build failure):
  Two layers agreed the API but never the DOM/test contract. Each side built
  what it thought the other expected. Unit tests were green on both sides.
  Then 100% of the e2e suite failed at the seam — because nobody owned the
  selectors/ids/flows the end-to-end tests assert against, and the two sides
  had silently diverged. The seam was a boundary neither agent owned.

  THE FIX: PIN the FULL contract for EVERY shared seam BEFORE fan-out.
  A seam is any boundary 2+ agents touch from opposite sides: API, DOM,
  events/messages, data schema, AND the e2e/test contract. Each gets one
  pinned file here as the single source of truth both sides build against.

  ┌─────────────────────────────────────────────────────────────────────┐
  │  GATE: PARALLEL FAN-OUT (P6) IS BLOCKED until EVERY shared seam has a  │
  │  contract with Status: pinned. e2e tests derive from these files.     │
  │  The conformance hook (R8) traces each module back to its seam        │
  │  contract — a module touching an unpinned seam fails conformance.     │
  └─────────────────────────────────────────────────────────────────────┘

  Copy this file once per seam, name it for the seam
  (e.g. 04-spec/contracts/lesson-api.md, 04-spec/contracts/manipulative-dom.md),
  fill every section, then flip Status to `pinned`.
-->

# Seam Contract — <seam name>

> Parallel fan-out is BLOCKED until **every** shared seam has a `pinned`
> contract. This is the single source of truth both sides build against; if
> the code and this file disagree, this file wins until it is amended here.

## Seam

What boundary this is, in one line. Name the two surfaces it separates and the
artifact that crosses it.

- **Boundary**: e.g. "lesson API between the lesson service and the web client",
  or "the manipulative DOM + test contract between the React component and the
  e2e suite".
- **What crosses it**: e.g. JSON over HTTP, DOM the tests query, events on a bus,
  rows in a table.

## Owned by

The single lead/agent that **owns** this contract. One owner, named — the
reference-build failure was a seam neither side owned, so changes drifted with
no arbiter. The owner is the only one who may amend a `pinned` contract, and
amendments re-derive the tests below.

- **Owner**: `<agent / lead name>`

## Parties

Every agent/module that builds **to** this contract — all sides, not just one.
Each party builds to the pinned text here, not to its own assumption of the
other side.

| Party (agent / module) | Side of the seam | Builds / consumes |
|------------------------|------------------|-------------------|
| `<agent A>`            | producer         | e.g. serves the endpoint, renders the DOM, emits the event |
| `<agent B>`            | consumer         | e.g. calls the endpoint, queries the DOM, handles the event |

## The full contract

Every facet the parties share — **not just the API**. Fill only the subsections
that apply to this seam, but be exhaustive within them: an unstated facet is
exactly how the reference build failed. Each facet must be concrete enough that
both sides can build to it with zero further conversation.

### API (endpoints / types)

- **Endpoints / methods**: verb + path (or function signature) per operation.
- **Request shape**: types, required vs optional fields, units, defaults.
- **Response shape**: types, status codes, nullability, ordering guarantees.
- **Auth / headers**: what every call must carry.

### DOM (selectors / structure the tests assert)

The DOM facet is the one the reference build skipped. Pin the **exact**
selectors and structure the e2e tests will query — these are part of the
contract, not an implementation detail the producer chooses later.

- **Stable selectors / ids**: e.g. `[data-testid="..."]`, element ids — the
  exact strings both the component and the tests use.
- **Structure / hierarchy**: required parent/child relationships, ARIA roles,
  attributes the tests read.
- **Rendered states**: what the DOM looks like per state (loading, empty,
  error, success) so assertions are unambiguous.

### Events / messages

- **Event/message names**: exact strings on the bus/channel.
- **Payload shape**: types and required fields.
- **Ordering / delivery**: guaranteed order? at-least-once? idempotency keys?

### Data schema

- **Tables / collections / files**: names and shapes.
- **Fields**: types, constraints, nullability, units, enums.
- **Keys / relations / migrations**: primary/foreign keys, indexes, versioning.

### Error / edge contract

- **Error shape**: the exact error object/format both sides agree on.
- **Edge cases**: empty, missing, oversized, concurrent, timeout — and the
  defined behavior for each. An undecided edge is a seam crack.

### E2E / test contract

The point of the loop. Pin the **exact** selectors/ids/flows the end-to-end
tests will assert — this is what made the reference build's "green" real
instead of two sides passing their own unit tests while the seam was broken.

- **Selectors / ids the e2e suite uses**: the exact strings (must match the DOM
  facet above verbatim).
- **Flows asserted**: the user/system journeys the e2e tests walk, step by step.
- **Assertions per flow**: what must be true at each step (visible text, state,
  network call, DB row).
- **Fixtures / seed data**: the deterministic data the e2e run requires.

## Derived tests

The e2e / integration tests generated **from** this contract (not hand-written
to match the code after the fact). List them here so the link is auditable; the
conformance hook (R8) traces each module to this file, and `verify.sh` must run
these e2e tests green before `ship-gate.sh` will release.

| Test file / id | Asserts which part of the contract |
|----------------|-------------------------------------|
| `<path/to/e2e.spec>` | e.g. flow X end-to-end via the pinned selectors |
| `<path/to/integration.spec>` | e.g. response shape + error contract |

## Status

`draft` → `pinned`

- **draft** — still being negotiated; fan-out for this seam is BLOCKED.
- **pinned** — owner has frozen the contract; the derived tests exist; fan-out
  for parties on this seam **may begin**. Amending a pinned contract is the
  owner's call and re-derives the tests above.

**Current status**: `draft`
