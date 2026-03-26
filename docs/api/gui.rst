minerva.gui
===========

Package nickname: ``minerva-gui``

This package defines the widget protocol, layout containers, and concrete
widgets used by Minerva's Lisp-side UI system.

Core structs
------------

``rect``
  ``(make-rect :x int :y int :width int :height int)``

  Accessors: ``rect-x``, ``rect-y``, ``rect-width``, ``rect-height``.

``size-request``
  ``(make-size-request :min-width int :min-height int :expand-x bool :expand-y bool)``

  Accessors: ``size-request-min-width``, ``size-request-min-height``,
  ``size-request-expand-x``, ``size-request-expand-y``.

Widget protocol
---------------

``widget``
  Base class for all widgets.

  Key accessors:

- ``widget-layout-rect``
- ``widget-content-alignment`` (combined alignment keyword such as
  ``:top-left``, ``:center``, ``:bottom-right``)
- ``widget-margin-left``, ``widget-margin-right``,
  ``widget-margin-top``, ``widget-margin-bottom``

Generic functions:

- ``(measure widget)`` → returns ``size-request``
- ``(layout widget rect)`` → assigns concrete geometry
- ``(render widget backend-window)`` → draws via backend

Measurement helpers:

- ``(measure-min-width widget)``
- ``(measure-min-height widget)``
- ``(measure-expand-x widget)``
- ``(measure-expand-y widget)``

Root widget
-----------

``window`` class

Slots/accessors:

- ``window-width``
- ``window-height``
- ``window-child`` (required single child)

Behavior:

- ``measure`` delegates minimum size to child
- ``layout`` sets root bounds from ``window-width``/``window-height`` and
  lays out child
- ``render`` delegates to child

Containers
----------

``hbox`` class

Slots/accessors:

- ``hbox-children``
- ``hbox-spacing``
- ``hbox-align-y`` (``:start``, ``:center``, ``:end``)

Behavior: horizontal packing with spacing and extra-width split among
children whose ``measure`` has ``expand-x`` true.

``vbox`` class

Slots/accessors:

- ``vbox-children``
- ``vbox-spacing``
- ``vbox-align-x`` (``:start``, ``:center``, ``:end``)

Behavior: vertical packing with spacing and extra-height split among
children whose ``measure`` has ``expand-y`` true.

Leaf widgets
------------

``color-rect`` class

Slots/accessors:

- ``color-rect-min-width``, ``color-rect-min-height``
- ``color-rect-expand-x``, ``color-rect-expand-y``
- ``color-rect-color`` (``(r g b a)`` list)

Behavior: reports configured size request and fills its layout rect in render.

``filler`` class

Slots/accessors:

- ``filler-min-width``, ``filler-min-height``
- ``filler-expand-x``, ``filler-expand-y``

Behavior: participates in layout expansion, renders nothing.

Image widgets
-------------

``image`` class

Slots/accessors:

- ``image-surface``
- ``image-draw-rect``

Behavior:

- ``measure`` uses surface dimensions
- ``layout`` computes clipped destination draw rect
- ``render`` draws clipped source region using ``minerva.gfx:draw-surface-rect``

``nine-patch`` class

Slots/accessors:

- ``nine-patch-surface``
- ``nine-patch-border-left``, ``nine-patch-border-right``,
  ``nine-patch-border-top``, ``nine-patch-border-bottom``
- ``nine-patch-child``
- ``nine-patch-content-rect``

Behavior:

- ``measure`` = borders + child minimum
- ``layout`` computes content rect and lays out optional child
- ``render`` draws 9 scaled segments from source surface to destination rect,
  then renders optional child

Usage sketch
------------

.. code-block:: lisp

   (let* ((leaf-a (make-instance 'minerva.gui:color-rect
                                 :min-width 100 :min-height 40
                                 :expand-x t
                                 :color '(200 60 60 255)))
          (leaf-b (make-instance 'minerva.gui:filler :expand-x t))
          (root (make-instance 'minerva.gui:window
                               :width 800 :height 600
                               :child (make-instance 'minerva.gui:hbox
                                                     :spacing 8
                                                     :children (list leaf-a leaf-b)))))
     (minerva.gui:layout root (minerva.gui:make-rect :x 0 :y 0 :width 800 :height 600)))
