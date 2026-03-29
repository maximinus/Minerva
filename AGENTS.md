# AGENTS Quick Notes

## Project shape
- Minerva is a Lisp-first GUI/editor project.
- Native C/SDL3 layer is a thin bridge only (window/events/drawing/resources).
- Do not move widget/layout/editor logic into C.

## Core boundary rule
- Lisp owns: layout, widgets, app/editor state, behavior.
- Native owns: low-level platform/rendering primitives.

## Current workflow (tool mode by default)
- Fast load check: `./check_load.sh`
- Full tests: `./run_tests.sh`
- Native smoke: `./run_smoke.sh`
- Interactive debugger run: `./debug_tests.sh`

## Tooling expectations
- Use non-interactive scripts for automation/LLM loops.
- Keep exit codes reliable; avoid hanging in SBCL debugger in tool mode.
- Logs are written to `.logs/`.

## Error/condition conventions
- Prefer project conditions from `src/conditions.lisp`.
- FFI/resource failures should be raised at the Lisp FFI wrapper boundary (`src/gfx/backend.lisp`).

## Practical constraints
- Keep changes minimal and scoped.
- Preserve existing architecture and test flow.
- Update docs/scripts when changing developer workflow.

## Lisp GUI coding notes
- Prefer existing widget capabilities over custom one-off logic.
- Prefer existing helper structs for cross-function data (e.g., `size`, `rect`).
