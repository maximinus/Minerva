minerva.conditions
==================

Package nickname: ``minerva-cond``

This package defines project-specific condition types used throughout Minerva.

Base condition
--------------

``minerva-error``
  Root condition for Minerva failures.

Slots / readers:

- ``minerva-error-phase`` → phase keyword (default ``:unknown``)
- ``minerva-error-message`` → human-readable message
- ``minerva-error-operation`` → operation identifier (string/symbol or ``NIL``)
- ``minerva-error-native-error`` → backend/native error text if available
- ``minerva-error-details`` → extra details payload

Specialized conditions
----------------------

- ``minerva-ffi-error``: Failures at FFI/backend call boundary.
- ``minerva-resource-error``: Resource acquisition/use failures (surfaces/fonts/files).
- ``minerva-layout-error``: Layout/measurement domain failures.
- ``minerva-widget-error``: Widget model/rendering failures.
- ``minerva-test-error``: Test-layer specific Minerva failures.

Handling pattern
----------------

.. code-block:: lisp

   (handler-case
       (minerva.gfx:create-window :title "Demo" :width 800 :height 600)
     (minerva.conditions:minerva-error (c)
       (format t "~&Phase: ~A~%Message: ~A~%"
               (minerva.conditions:minerva-error-phase c)
               (minerva.conditions:minerva-error-message c))))
