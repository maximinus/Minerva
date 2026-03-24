# Changelog

All notable changes to this project will be documented in this file.

## [0.05] - 24 March 2026

### Added
- Milestone 3 graphics/resource API across native + Lisp layers:
  - surface creation/loading/query/destroy
  - surface blit variants (full, source-rect, source-rect scaled)
  - window surface draw variants needed by widgets and 9-patch rendering
  - font resource handle API with text measurement and text-to-surface rendering
- Lisp-side geometry/resource value types in `minerva.gfx`:
  - `position`, `rect`, `color`
  - `backend-surface`, `backend-font` wrappers
- New GUI widgets in `src/minerva/gui/core.lisp`:
  - `image` (native-size draw, alignment, clipping, no scaling)
  - `nine-patch` (single-child container with border-defined content region and 9-slice rendering)
- New tooling/automation layer for reliable non-interactive workflows:
  - `check_load.sh`, `run_tests.sh`, `run_smoke.sh` (tool mode)
  - `debug_tests.sh` (interactive debugger mode)
  - Lisp tooling entry points under `tools/`
  - VS Code tasks at `.vscode/tasks.json`
- Project condition hierarchy in `src/minerva/conditions.lisp`.
- Agent quick-reference file at project root: `AGENTS.md`.

### Changed
- `minerva.asd` now loads:
  - `src/minerva/conditions.lisp`
  - `src/minerva/gfx/ffi.lisp`
  - `src/minerva/gfx/backend.lisp`
  - `src/minerva/gui/core.lisp`
- FFI wrapper boundary (`src/minerva/gfx/backend.lisp`) now raises project-specific conditions for FFI/resource failures.
- Test harness tracks current test symbol for improved crash-context reporting in tool mode.
- `README.md` updated with tool vs interactive execution modes and new scripts.

### Verified
- `./check_load.sh` succeeds in tool mode.
- `./run_tests.sh` succeeds with all GUI tests passing (`124 assertions`).

## [0.04] - 23 March 2026

### Added
- Added project ASDF definition at `minerva.asd` with:
  - `minerva` system loading `src/minerva/gui/core.lisp`
  - `minerva/tests` system loading `tests/minerva/gui/tests.lisp`
  - `asdf:test-op` hook invoking `minerva.gui:run-gui-layout-tests`
- Added root test folder structure mirroring source layout:
  - `tests/minerva/gui/tests.lisp`

### Changed
- GUI layout tests now run through ASDF instead of script-relative file loading.
- Root `README.md` now includes a "How to run tests" section with the SBCL/ASDF command.

### Removed
- Removed old test location at `src/minerva/gui/tests.lisp`.

## [0.03] - 23 March 2026

### Changed
- Removed all Lisp compatibility shims and switched to direct namespaced module loading.
- `blue-rectangle-demo.lisp` now loads only:
  - `src/minerva/gfx/ffi.lisp`
  - `src/minerva/gfx/backend.lisp`
- `minerva.gfx` backend now imports from `minerva.gfx.ffi` directly.

### Added
- New namespaced FFI module at `src/minerva/gfx/ffi.lisp`.

### Removed
- `src/minerva-ffi.lisp`
- `src/minerva-backend.lisp`
- `src/minerva/backend-compat.lisp`

### Verified
- `sbcl --script src/blue-rectangle-demo.lisp` executes successfully after shim removal.

## [0.02] - 23 March 2026

### Changed
- Introduced namespaced graphics backend package `minerva.gfx` (nickname `minerva-gfx`) for Phase 2/3 Lisp backend code.
- Added folder-based Lisp module structure for backend code:
  - `src/minerva/gfx/backend.lisp`
  - `src/minerva/backend-compat.lisp`
- Updated demo script to load and call the namespaced backend package from the new folder structure.

### Added
- Compatibility package `minerva.backend` re-exporting `minerva.gfx` API symbols to preserve legacy call sites.
- Legacy loader shim in `src/minerva-backend.lisp` now forwards to the new module paths.

### Verified
- `sbcl --script src/blue-rectangle-demo.lisp` runs successfully after the refactor.

## [0.01] - 23 March 2026

### Added
- Initial native bridge for Milestone 1 in `native/`.
- Public C API header at `native/include/minerva_native.h` with:
  - lifecycle (`init`, `minerva_shutdown`, `last_error`)
  - window management (`Window*` opaque handle + create/destroy/size/close helpers)
  - event polling (`EventType`, `Event`, `poll_event`)
  - frame drawing (`begin_frame`, `clear`, `fill_rect`, `end_frame`)
  - timing (`ticks_ms`, `sleep_ms`)
- SDL3-backed implementation at `native/src/minerva_native.c`.
- Native smoke test at `native/tests/smoke_native.c` that opens a window, draws a blue rectangle, and exits cleanly.
- CMake build setup at `native/CMakeLists.txt` for:
  - `libminerva_native.so`
  - `minerva_native_smoke`
  - optional SDL3 auto-fetch via CMake `FetchContent` when system SDL3 is unavailable.
- Native bridge build/run documentation at `native/README.md`.

### Changed
- Project docs updated to remove legacy `Handy*` naming and use `Window`/`Event` naming consistently.
- Root `README.md` updated with native bridge build/run instructions.

### Notes
- The lifecycle shutdown symbol is currently `minerva_shutdown` to avoid collision with the POSIX `shutdown` symbol.
