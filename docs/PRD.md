# FORGE — Dynamic AI Build Workflow

## What is this?

A tool that takes a product idea or requirements document and builds the entire application — planning, coding, testing, and deploying — with minimal human input. You check in at four decision points. Everything else runs autonomously.

While it builds, you can watch everything happening in real time through a live dashboard. Documentation is created as it goes, not bolted on at the end. Tests are generated before code is written, so you know what "done" looks like before anyone starts building.

When it finishes, you get a deployed application, a complete documentation site, a test report, and a timeline of everything that happened during the build.

## Who is this for?

An AI engineering lead who wants to turn a stakeholder's requirements into a shipped, tested, documented application using AI agents — without babysitting every step.

## What should it do?

### Build the application

Given a product idea or PRD document, the system should:

- Understand what needs to be built by consulting expert panels and doing research
- Write a detailed plan and get human approval before starting
- Assign work to a team of AI agents that build in parallel
- Review every piece of code through multiple specialized lenses before merging
- Test everything against criteria generated from the plan
- Fix problems automatically when possible, flag them for humans when not
- Deploy the result

### Show me what's happening while it builds

I want to open a dashboard and immediately see:

- What phase the build is in
- Which agents are working on what
- Whether anything is blocked or broken
- How much of the plan is complete
- A timeline of the entire build, like a Gantt chart

This should be prepopulated when the build starts — I should see the full plan laid out, not an empty screen that fills in as things happen. As the build progresses, the bars fill in and status updates in real time.

### Create documentation as it builds, not after

Every phase should produce documentation automatically. I don't want to run a separate command — the docs should update whenever a phase completes. If I look at the documentation mid-build, it should reflect everything that's been completed so far.

At the end, all the documentation should be reorganized into a clean, navigable site I can hand to a stakeholder.

### Make test results visible everywhere

I should see test pass/fail status in the dashboard, in the documentation, and at every decision point. Not buried in a log file. If 3 out of 50 tests are failing, I should know that from any view — the dashboard health screen, the phase status, the documentation coverage page.

### Wire everything together

The build status, the documentation, the test results, and the dashboard should all know about each other. When a phase completes, all four should update. When I'm at a decision point, I should see one combined view — not four separate things I have to cross-reference.

## What already exists?

- The build pipeline (13 phases, 4 decision points, 3 agent terminals) — working
- The observability dashboard (4 visual themes, event streaming) — working but not prepopulated
- The documentation generator (`/docs` skill) — working but manual
- The eval harness (task-00, immutable tests) — working but results not surfaced

The gap is the integration. These four systems work independently but don't talk to each other.

## What does "done" look like?

1. I run `/forge "build a math tutor for kids"` and immediately see the full build plan in the dashboard
2. I walk away and come back in an hour. The dashboard tells me "Phase 6, 5 of 8 tasks done, 2 tests failing, docs current through Phase 5"
3. At the ship decision point, I see one screen with: working app, test results, doc completeness, cost, and remaining gaps
4. After deploy, I have a documentation site I can send to a stakeholder without any manual cleanup

## Constraints

- No external dependencies beyond Python 3 and Claude Code
- Dashboard must work offline (self-contained HTML)
- Must work with the existing pipeline — this is integration, not a redesign
- Documentation generation should not block the build (run in background)
- Everything the system produces must be explainable in plain English

## Open questions

1. Should the dashboard show doc generation happening in real time, or just show "docs: current" / "docs: stale"?
2. When I replay a completed build, should it show the documentation state at each point in time, or just the events?
3. Should the integrated gate view be a new dashboard tab, or a generated HTML file?
