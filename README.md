# Minerva Lisp IDE

## Lisp GUI and Editor Project

This project is an experiment in building a small GUI system in Lisp, with the long-term goal of creating a simple text editor and eventually growing it into a Lisp IDE.

The project is split into two main parts. The first is a small native backend, written in C, which wraps a rendering and windowing library and exposes a very small, clean API to Lisp. The second is the Lisp side, where the actual GUI system is built: layout, widgets, rendering logic, and later editor behaviour.

The current focus is on building the foundations in small, testable steps. Rather than starting with a full IDE, the project begins with a minimal GUI framework and a layout engine. The idea is to make progress in layers: first get a window on screen, then create a layout system, then basic widgets, and only after that move toward text editing and IDE features.

A key design goal is to keep as much logic as possible in Lisp, while using the native backend only for low-level tasks like drawing, window management, and input. This keeps the higher-level GUI code portable, easier to reason about, and easier to test.

The GUI model is tree-based. Widgets are arranged in containers such as horizontal and vertical boxes, and layout is computed separately from rendering. This makes it possible to test layout behaviour without drawing anything, which is important for keeping the system reliable as it grows.

In the long run, the aim is not just to make a GUI toolkit, but to create a practical Lisp-based editor environment that can be extended step by step without losing control of the architecture.

## Tooling modes

Minerva now supports two execution modes:

- Tool mode (default for scripts/tasks): non-interactive, debugger disabled, reliable exit codes.
- Interactive mode (manual debugging): debugger enabled with full restarts/backtraces.

## How to run tests

Minerva uses ASDF systems for loading and test execution.

From a terminal in the project root (tool mode):

```bash
./run_tests.sh
```

Interactive debug mode:

```bash
./debug_tests.sh
```

Fast load/syntax check (recommended before full tests):

```bash
./check_load.sh
```

Optional native smoke check:

```bash
./run_smoke.sh
```

## Rebuild native bridge (C)

If you change code under `native/src`, rebuild the native bridge from the project root:

```bash
cmake --build build/native
```

If build files are missing or you want to reconfigure first:

```bash
cmake -S native -B build/native
cmake --build build/native
```

For a clean rebuild:

```bash
cmake --build build/native --clean-first
```

If you need the equivalent manual command:

```bash
sbcl --eval '(require :asdf)' \
     --eval '(asdf:load-asd (truename "minerva.asd"))' \
     --eval '(asdf:test-system "minerva/tests")' \
     --quit
```

Logs for tool mode are written under `.logs/`.

`run_tests.sh` currently runs the layout-engine unit tests in `tests/minerva/gui/tests.lisp`.

A successful run ends with:

```text
Executed 124 assertions.
All GUI layout tests passed.
```
