Getting Started
===============

Scope
-----

These docs describe Lisp-side APIs from:

- ``src/minerva/conditions.lisp``
- ``src/minerva/gfx/ffi.lisp``
- ``src/minerva/gfx/backend.lisp``
- ``src/minerva/gui/core.lisp``

The native C layer is intentionally not documented here.

Loading packages
----------------

A typical REPL session:

.. code-block:: lisp

   (ql:quickload :minerva)

   ;; Core GUI/layout package
   (use-package :minerva.gui)

   ;; Rendering/backend package
   (use-package :minerva.gfx)

Key package roles
-----------------

- ``minerva.conditions``: Project-specific condition types for reporting errors.
- ``minerva.gfx``: User-facing rendering/window/surface/font API.
- ``minerva.gfx.ffi``: Low-level foreign bindings used by ``minerva.gfx``.
- ``minerva.gui``: Widget system, measurement/layout, and rendering protocol.
