# Minerva Lisp IDE

Minerva is aiming to be a modern Lisp IDE.
It is written in Lisp and uses SDL3 as a rendering engine.

## License

GPL 3.0

## Native bridge (Milestone 1)

The SDL3-backed native bridge lives in `native/`.

Build and run the native smoke test:

```bash
cmake -S native -B build/native
cmake --build build/native
./build/native/minerva_native_smoke
```

## Lisp demo (Milestone 1 Phase 2+3)

Requirements:
- SBCL (tested with v2.1)

Run the Lisp blue-rectangle demo:

```bash
cmake --build build/native
sbcl --script src/blue-rectangle-demo.lisp
```

This loads the native bridge through SBCL FFI and shows a black window with a blue rectangle.

