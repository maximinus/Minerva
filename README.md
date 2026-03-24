# Minerva Lisp IDE

## Lisp GUI and Editor Project

This project is an experiment in building a small GUI system in Lisp, with the long-term goal of creating a simple text editor and eventually growing it into a Lisp IDE.

The project is split into two main parts. The first is a small native backend, written in C, which wraps a rendering and windowing library and exposes a very small, clean API to Lisp. The second is the Lisp side, where the actual GUI system is built: layout, widgets, rendering logic, and later editor behaviour.

The current focus is on building the foundations in small, testable steps. Rather than starting with a full IDE, the project begins with a minimal GUI framework and a layout engine. The idea is to make progress in layers: first get a window on screen, then create a layout system, then basic widgets, and only after that move toward text editing and IDE features.

A key design goal is to keep as much logic as possible in Lisp, while using the native backend only for low-level tasks like drawing, window management, and input. This keeps the higher-level GUI code portable, easier to reason about, and easier to test.

The GUI model is tree-based. Widgets are arranged in containers such as horizontal and vertical boxes, and layout is computed separately from rendering. This makes it possible to test layout behaviour without drawing anything, which is important for keeping the system reliable as it grows.

In the long run, the aim is not just to make a GUI toolkit, but to create a practical Lisp-based editor environment that can be extended step by step without losing control of the architecture.

## How to run tests

Minerva uses ASDF systems for loading and test execution.

From a terminal in the project root:

```bash
./run_tests.sh
```

If you need the equivalent manual command:

```bash
sbcl --eval '(require :asdf)' \
     --eval '(asdf:load-asd (truename "minerva.asd"))' \
     --eval '(asdf:test-system "minerva/tests")' \
     --quit
```

This runs the layout-engine unit tests in `tests/minerva/gui/tests.lisp`.

A successful run ends with:

```text
Executed 115 assertions.
All GUI layout tests passed.
```
