# Minerva Native Bridge (Phase 1)

This directory contains the SDL3-backed C bridge for Milestone 1.

## Requirements
- CMake 3.20+
- C compiler (gcc/clang)

SDL3 can be provided in either way:
- Installed system development package (`SDL3Config.cmake` available)
- Automatically fetched from GitHub during configure (default behavior)

## Build

```bash
cmake -S native -B build/native
cmake --build build/native
```

To disable auto-fetch and require a system SDL3 install:

```bash
cmake -S native -B build/native -DMINERVA_FETCH_SDL3=OFF
```

## Run smoke test

```bash
./build/native/minerva_native_smoke
```

The smoke test opens a window, draws a blue rectangle on a black background, then exits.

## API header
Public API: `native/include/minerva_native.h`
