minerva.gfx and minerva.gfx.ffi
===============================

The ``minerva.gfx`` package is the user-facing graphics API. It wraps
``minerva.gfx.ffi`` and raises Minerva conditions on failure.

Data types
----------

``position`` struct
  Constructor: ``(make-position :x int :y int)``

  Accessors: ``position-x``, ``position-y``

``rect`` struct
  Constructor: ``(make-rect :x int :y int :width int :height int)``

  Accessors: ``rect-x``, ``rect-y``, ``rect-width``, ``rect-height``

``color`` struct
  Constructor: ``(make-color :r int :g int :b int :a int)``

  Accessors: ``color-r``, ``color-g``, ``color-b``, ``color-a``

Opaque backend classes
----------------------

- ``backend-window`` (slot/accessor: ``pointer``)
- ``backend-surface`` (slot/accessor: ``pointer``)
- ``backend-font`` (slot/accessor: ``pointer``)

You generally create and pass these through API calls rather than
manipulating internals.

Lifecycle
---------

``(init-backend)``
  Loads native libraries and initializes backend. Returns ``T``.

``(shutdown-backend)``
  Shuts backend down. Returns ``T``.

``(backend-last-error)``
  Returns current native/backend error string.

Window API
----------

``(create-window &key (title "Minerva") (width 800) (height 600))``
  Creates a ``backend-window``.

``(destroy-window window)``
  Destroys native window and clears pointer. Returns ``T``.

``(window-should-close-p window)``
  Returns boolean-like Lisp truth value.

``(request-window-close window)``
  Requests graceful close. Returns ``T``.

``(window-size window)``
  Returns two values: ``width`` and ``height``.

Events and frame loop
---------------------

``(poll-events)``
  Returns a list of normalized event forms:

- ``(:quit)``
- ``(:window-resized width height)``
- ``(:key-down keycode)``
- ``(:key-up keycode)``
- ``(:mouse-button-down button x y)``
- ``(:mouse-button-up button x y)``
- ``(:mouse-move x y)``
- ``(:unknown-event type a b c)``

``(begin-frame window)``
``(clear-screen window r g b a)``
``(fill-rect window x y width height r g b a)``
``(end-frame window)``

All return ``T``.

Surface API
-----------

``(create-surface &key width height)``
  Creates blank ``backend-surface``.

``(load-surface path)``
  Loads image file into ``backend-surface``.

``(destroy-surface surface)``
  Frees surface and clears pointer. Returns ``T``.

``(surface-width surface)``, ``(surface-height surface)``
  Return dimensions.

``(surface-rgba32-p surface)``
  True when surface format is RGBA32.

``(fill-surface-rect surface rect color)``
  Fills rectangular region. Returns ``T``.

``(read-surface-pixel surface position)``
  Returns a ``color`` struct.

Blitting and drawing
--------------------

``(blit-surface source destination dest-position)``
``(blit-surface-rect source source-rect destination dest-position)``
``(blit-surface-rect-scaled source source-rect destination dest-rect)``

``(draw-surface window surface dest-position)``
``(draw-surface-rect window surface source-rect dest-position)``
``(draw-surface-rect-scaled window surface source-rect dest-rect)``

Each call returns ``T`` or signals ``minerva-ffi-error``.

Font/text API
-------------

``(get-font name-or-path size)``
  Returns ``backend-font``.

``(destroy-font font)``
  Frees font pointer. Returns ``T``.

``(measure-text font text)``
  Returns two values: ``width`` and ``height``.

``(render-text-to-surface font text color)``
  Returns ``backend-surface`` containing rendered text.

Timing
------

``(ticks-ms)``
  Returns backend monotonic tick count in milliseconds.

``(sleep-ms ms)``
  Sleeps for ``ms`` milliseconds. Returns ``T``.

Low-level FFI package
---------------------

``minerva.gfx.ffi`` exports constants and raw foreign routines. Most users
should prefer ``minerva.gfx``.

Event constants:

- ``event-none``
- ``event-quit``
- ``event-window-resized``
- ``event-key-down``
- ``event-key-up``
- ``event-mouse-button-down``
- ``event-mouse-button-up``
- ``event-mouse-move``

Foreign handle/event types:

- ``c-window``, ``c-surface``, ``c-font``, ``c-event``

Raw exported functions include:

- Loader: ``ensure-native-library-loaded``
- Lifecycle: ``%init``, ``%shutdown``, ``%last-error``
- Window/event/frame: ``%window-create``, ``%window-destroy``,
  ``%window-should-close``, ``%window-request-close``, ``%window-get-size``,
  ``%poll-event``, ``%begin-frame``, ``%clear``, ``%fill-rect``, ``%end-frame``
- Surface: ``%surface-create-blank``, ``%surface-load-file``,
  ``%surface-destroy``, ``%surface-width``, ``%surface-height``,
  ``%surface-is-rgba32``, ``%surface-fill-rect``, ``%surface-read-pixel``,
  ``%surface-blit``, ``%surface-blit-rect``, ``%surface-blit-rect-scaled``
- Window surface drawing: ``%window-draw-surface``,
  ``%window-draw-surface-rect``, ``%window-draw-surface-rect-scaled``
- Font/text: ``%font-get``, ``%font-destroy``, ``%font-measure-text``,
  ``%font-render-text``
- Time: ``%ticks-ms``, ``%sleep-ms``
