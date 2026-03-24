# Milestone 1 Plan: Native Bridge + First Running Loop

## Milestone definition
Milestone 1 is complete when Lisp can initialize the native backend, open a window, poll events, render a black background with one blue rectangle every frame, close cleanly on quit, and shut down without leaking backend concepts outside the boundary.

## Scope constraints
- Keep the C/native layer as a tiny platform/rendering bridge.
- Keep all widget, layout, and editor logic out of C.
- Expose only the v1 API surface defined in `docs/project.md`.

## Non-goals for this milestone
- No GUI toolkit.
- No text editor features.
- No retained widget model.
- No SDL types/constants visible outside native implementation and low-level FFI module.

---

## Phase 0 — API boundary freeze

### Goals
- Define one public C header for the minimal API groups: lifecycle, window, events, drawing, timing.
- Use opaque handle types for window/context objects.
- Define a fixed event struct and enum for v1 event normalization.

### Testable outcomes
- Header contains only the approved v1 symbols (no extra functions).
- Header exposes no SDL types (`SDL_Window`, `SDL_Event`, etc.).
- Header can be included by a tiny C smoke program and compiled without implementation details.

### Exit criteria
- API list matches the Milestone 1 contract in `docs/project.md`.

---

## Phase 1 — Native SDL3 implementation

### Goals
- Implement the v1 API in C with SDL3 underneath.
- Add explicit error propagation via `last_error` and null/zero return semantics.
- Enforce simple ownership: create/destroy pairs and single-threaded operation.

### Testable outcomes
- Native library builds successfully as a shared library.
- `init`/`shutdown` run in a native smoke test without crash.
- `window_create` returns valid handle on success and null on failure.
- `window_destroy` can be called after successful create without crash.
- `poll_event` returns events through the fixed event struct.

### Exit criteria
- Native layer provides stable behavior for init, loop, and shutdown paths.

---

## Phase 2 — SBCL FFI bindings (raw + safe wrappers)

### Goals
- Add a low-level FFI layer mirroring C signatures.
- Add a safe Lisp wrapper layer used by the rest of the app.
- Normalize event values into Lisp-friendly forms.

### Testable outcomes
- Lisp can load the shared library and resolve all required symbols.
- Wrapper calls return expected Lisp values for success/failure paths.
- Event polling in Lisp yields normalized events (for example `(:quit)` / `(:mouse-move x y)`).
- SDL names/types are not referenced outside the low-level FFI module.

### Exit criteria
- One top-level Lisp API exists for backend lifecycle, window, events, drawing, and timing.

---

## Phase 3 — First running loop (blue rectangle proof)

### Goals
- Implement a minimal app loop in Lisp using only wrapper API.
- Process all pending events each frame.
- Render black clear + one blue rectangle + present each frame.
- Exit loop on quit/close signal and perform clean shutdown.

### Testable outcomes
- Running the app opens a titled window.
- Visible rendering: black background and fixed blue rectangle.
- Close button triggers loop exit in under 1 second.
- Program exits without crash and calls shutdown path exactly once.

### Exit criteria
- Demo reproducibly runs and exits cleanly on developer machine.

---

## Phase 4 — Bridge hardening and acceptance checks

### Goals
- Add a small milestone test set around boundary behavior.
- Add lightweight diagnostics to help verify lifecycle and frame loop health.
- Freeze v1 API after passing acceptance checks.

### Testable outcomes
- Automated or scripted checks cover:
  - init/shutdown stability
  - create/destroy window stability
  - short draw loop execution
  - representative failure path (`last_error` is populated)
- Runtime logs show backend init, window create, frame count window, and shutdown.
- No API changes made after freeze without explicit milestone update.

### Exit criteria
- Milestone acceptance checklist passes and v1 API is marked frozen.

---

## Milestone 1 acceptance checklist
- [ ] v1 header is minimal and SDL-opaque.
- [ ] Shared native library builds on target environment.
- [ ] SBCL can load and call every required symbol.
- [ ] Lisp wrappers hide raw FFI details from app code.
- [ ] App loop draws black + blue rectangle each frame.
- [ ] Quit event closes loop and triggers clean shutdown.
- [ ] Basic boundary tests and diagnostics are in place.
- [ ] v1 API declared frozen at milestone completion.

## Suggested execution order
1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3
5. Phase 4

## Definition of done (Milestone 1)
Milestone 1 is done when the acceptance checklist passes end-to-end and the team agrees to freeze the v1 native API while beginning Lisp-side layout work in the next milestone.
