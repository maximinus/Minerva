# Changelog

All notable changes to this project will be documented in this file.

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
