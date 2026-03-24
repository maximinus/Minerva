Project Minerva
===============

This project has a long term goal to build a Lisp IDE in LISP, with a custom GUI library.

The GUI library will use SDL3 as rendering engine, but we will create a C thin layer so the SDL internals are never exposed to Lisp.

The first milestone is not "build a GUI toolkit" and not even "build a text editor." It is:

**define a tiny native API that Lisp can call comfortably, implement it in SDL3, prove the loop works, then build upward in Lisp.**

That keeps the dangerous parts small and gives us a clean place to stop and test.

# Over-arching guide

## Stage 0 — define the boundary before writing code

The C native layer only needs to provide:

* window creation and shutdown
* event polling
* a very small drawing API
* timing
* maybe clipboard later
* maybe text drawing later

Its job is **not** to provide:

* widgets
* layout
* retained GUI objects
* editor logic
* menus
* text buffer logic

That means the native layer is a **platform/rendering bridge**, not a GUI system.

The Lisp side owns:

* application state
* layout engine
* widget behaviour
* command system
* later, editor state

This is important because otherwise the C layer quietly grows into a second project.

---

## Stage 1 — define the smallest useful Lisp-friendly API

The first exposed API to be:

* tiny
* stable
* boring
* easy to bind from SBCL
* easy to replace with another backend later

For the first milestone, I want to expose only these groups.

## 1. Lifecycle / context

These functions create and destroy the native context.

```c
int init(void);
void shutdown(void);
const char* last_error(void);
```

### Meaning

* `init`
  Starts the backend. Returns non-zero on success, zero on failure.
* `shutdown`
  Cleans up backend-level resources.
* `last_error`
  Returns the most recent human-readable error string.

### Lisp view

You would likely wrap these so Lisp gets:

* `init-gfx`
* `shutdown-gfx`
* `error-gfx`

---

## 2. Window management

We use opaque pointers or opaque handles, not exposed SDL structs.

```c
typedef struct Window Window;

Window* window_create(const char* title, int width, int height);
void window_destroy(Window* window);
int window_should_close(Window* window);
void window_request_close(Window* window);
void window_get_size(Window* window, int* width, int* height);
```

### Meaning

* `window_create`
  Creates a window and whatever rendering context belongs with it.
* `window_destroy`
  Frees it.
* `window_should_close`
  Lets Lisp know the app should end.
* `window_request_close`
  Useful if Lisp wants to trigger shutdown.
* `window_get_size`
  Used for layout later.

### Why this shape

Lisp should not know about `SDL_Window*`, renderer structs, or backend-specific details.

---

## 3. Event polling

For Lisp, the cleanest first version is:

* a fixed event struct
* one poll function

Something like:

```c
typedef enum {
    EVENT_NONE = 0,
    EVENT_QUIT,
    EVENT_WINDOW_RESIZED,
    EVENT_KEY_DOWN,
    EVENT_KEY_UP,
    EVENT_MOUSE_BUTTON_DOWN,
    EVENT_MOUSE_BUTTON_UP,
    EVENT_MOUSE_MOVE
} EventType;

typedef struct {
    EventType type;
    int a;
    int b;
    int c;
    int d;
} Event;

int poll_event(Event* out_event);
```

### Meaning

* returns non-zero if an event was written
* returns zero if no event is available

### Suggested field meaning for v1

Keep it simple:

* `WINDOW_RESIZED`: `a=width`, `b=height`
* `KEY_DOWN/UP`: `a=keycode`
* `MOUSE_BUTTON_DOWN/UP`: `a=button`, `b=x`, `c=y`
* `MOUSE_MOVE`: `a=x`, `b=y`

We can later evolve this into a richer struct, but this is enough to start.

### Why not expose SDL events directly?

Because then Lisp becomes tied to SDL unions, constants, and event semantics. That defeats the point of the abstraction.

---

## 4. Frame and drawing

For the first milestone, we only need:

* clear screen
* fill rectangle
* present frame

```c
void begin_frame(Window* window);
void clear(Window* window, unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void fill_rect(Window* window, int x, int y, int width, int height,
                     unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void end_frame(Window* window);
```

### Meaning

* `begin_frame`
  Marks the start of drawing for a frame
* `clear`
  Clears the whole render target
* `fill_rect`
  Draws a solid rectangle
* `end_frame`
  Presents the frame

### Why no lines, circles, textures yet?

Because we do not need them to prove the boundary works.

---

## 5. Timing

Useful for the loop and later for cursor blinking, throttling, animation, etc.

```c
unsigned long long ticks_ms(void);
void sleep_ms(int ms);
```

### Meaning

* `ticks_ms` gives elapsed milliseconds
* `sleep_ms` avoids a hot CPU loop

---

# Minimal API summary

For the first version, we will stop here::

## Lifecycle

* `init`
* `shutdown`
* `last_error`

## Window

* `window_create`
* `window_destroy`
* `window_should_close`
* `window_request_close`
* `window_get_size`

## Events

* `poll_event`

## Drawing

* `begin_frame`
* `clear`
* `fill_rect`
* `end_frame`

## Timing

* `ticks_ms`
* `sleep_ms`

That is enough to:

* open a window
* handle quit
* draw a blue rectangle
* run a main loop

Which is exactly the first proof you want.

---

# Stage 2 — implement the API in SDL3

At this stage, the goal is not elegance. It is:

* correct build
* stable boundary
* predictable ownership
* clean error handling

## C-side rules

### 1. Opaque types only

The header visible to Lisp should contain opaque declarations like:

```c
typedef struct Window Window;
```

The actual struct definition stays private in the `.c` file.

That means Lisp cannot accidentally depend on SDL internals.

### 2. Every failure path is explicit

Every exported function should either:

* return success/failure
* or return null on failure and set the last error

Do not make Lisp guess.

### 3. One owner, one destroy function

If `window_create` creates it, only `window_destroy` destroys it.

Do not expose mixed ownership rules.

### 4. Keep the backend single-threaded at first

Do not introduce threads in the native layer yet.

### 5. Avoid callbacks into Lisp

Poll from Lisp; do not let SDL call Lisp.

That keeps the boundary much safer and simpler.

---

# Stage 3 — bind this API in SBCL

Now write the SBCL FFI bindings.

The Lisp side should not expose raw foreign calls to the rest of the program. Instead, create a thin Lisp wrapper layer.

For example:

## Low-level foreign binding layer

This mirrors the C API exactly.

Examples of names:

* `%init`
* `%window-create`
* `%fill-rect`

## Safe Lisp wrapper layer

This is what the rest of the program uses.

Examples:

* `init-backend`
* `create-window`
* `destroy-window`
* `poll-event`
* `clear-screen`
* `fill-rect`
* `ticks-ms`

This wrapper layer should:

* check null returns
* signal Lisp conditions on failure
* convert event structs into Lisp values
* hide foreign pointers inside Lisp objects if possible

For example, `poll-event` should probably return something Lispy, such as:

```lisp
(:quit)
(:window-resized 1200 800)
(:key-down :escape)
(:mouse-move 200 150)
```

not a raw foreign struct.

That will make the later layout engine much easier to write.

---

# Stage 4 — first running milestone

This stage is deliberately tiny.

## Goal

A Lisp program that:

* initializes the backend
* creates a window
* enters a loop
* polls events
* closes on quit
* clears the background
* draws one blue rectangle
* presents the frame

## Behaviour

Something like:

* black background
* blue rectangle at fixed position
* 60-ish FPS or just a simple loop with light sleeping
* quit when close button is pressed

## Why this matters

This proves:

* C library builds
* Lisp can load it
* FFI boundary works
* event polling works
* frame drawing works
* resource ownership is correct
* your development loop is real

This is the first “the project exists” milestone.

---

# Stage 5 — strengthen the bridge before climbing upward

Once the blue rectangle loop works, we will not just jump straight to widgets.
First we add a little discipline.

## Add tests around the boundary

You want at least:

* backend init/shutdown does not crash
* window can be created and destroyed
* drawing loop runs for a short period
* error handling works for invalid cases if possible

## Add diagnostic facilities

A small debug log helps:

* what backend loaded
* window created
* frame count
* last error on failure

## Freeze the v1 API

Do not keep changing the boundary casually.
Try to keep it stable while you build the Lisp side.

---

# Stage 6 — build a Lisp layout engine

Once the native layer works, the next real project begins.

The layout engine should be in Lisp, not C.

## Responsibilities of the layout engine

* define rectangles and regions
* split space horizontally and vertically
* padding and margin
* alignment
* min/preferred sizes
* allocate child rects inside parent rects

At first, make it very simple.

## First layout primitives

I would start with these concepts:

* fixed-size item
* fill item
* vertical stack
* horizontal stack
* padding
* maybe overlay later

For example, a layout input might describe:

* window rect
* vertical stack

  * toolbar fixed height 30
  * main area fill
  * status bar fixed height 20

And the output is just rectangles.

That is enough to place widgets later.

## Why layout first?

Because once you have layout:

* buttons can live somewhere
* sidebars can exist
* editor panes can exist
* widgets stop being “draw at hardcoded x/y”

Without layout, UI growth becomes messy very quickly.

---

# Stage 7 — define the first widget model

Still in Lisp.

At this stage, do not build a giant general GUI toolkit. Build only what the text editor will need.

## Suggested first widgets

* panel / box
* label
* button
* vertical container
* horizontal container
* scrollable region later
* text display later
* text input later

But since the goal is a text editor, we should be careful:
We do not want to spend months making normal widgets before touching text editing.

So the widget phase should be shallow.

## Widget responsibilities

Each widget should, in effect:

* receive a rectangle
* inspect current input state
* produce draw calls
* maybe emit actions

This fits well with the immediate-mode direction we want to take.

---

# Stage 8 — move toward editor-specific pieces

Only after the above works do you start the actual editor journey.

That likely means:

* text buffer model
* caret
* selection
* line rendering
* scrolling
* keyboard editing
* undo/redo

That is its own major phase and deserves to be treated as such.

---

# Suggested development order

Here is the whole path in compact form.

## Phase A — native bridge

1. Define tiny backend API
2. Implement it in C using SDL3
3. Build shared library
4. Bind from SBCL
5. Open window and draw blue rectangle

## Phase B — Lisp GUI foundations

6. Normalize events into Lisp-friendly values
7. Add frame/update structure
8. Build simple layout engine
9. Add a few tiny drawing helpers in Lisp
10. Build first minimal widgets

## Phase C — editor foundations

11. Build text buffer model
12. Render text lines
13. Add caret and scrolling
14. Add keyboard editing
15. Add save/load
16. Add simple menus/commands later

---

# Suggested Lisp-friendly wrappers

Above the raw FFI, I would want the Lisp API to look roughly like this:

## Backend lifecycle

* `init-backend`
* `shutdown-backend`
* `backend-last-error`

## Window

* `create-window`
* `destroy-window`
* `window-size`
* `window-should-close-p`

## Events

* `poll-events`

Where `poll-events` returns a Lisp list of normalized events for the frame.

## Drawing

* `begin-frame`
* `clear-screen`
* `fill-rect`
* `end-frame`

## Timing

* `ticks-ms`
* `sleep-ms`

That is the API the rest of Lisp should use first.

---

# A concrete definition of the first milestone

* Open a simple window, draw a blue rectangle, and just cycle until the user closes the window.

I will define “done” as:

* Lisp can call `init-backend`
* Lisp can create a window titled something like `"Minerva"`
* Each frame:

  * poll all events
  * if quit event occurs, set close flag
  * clear screen to black
  * draw one blue rectangle
  * present frame
  * sleep a tiny amount if needed
* Window closes cleanly
* `shutdown-backend` runs without error
* No SDL names appear outside the native boundary or the low-level FFI module

That last point is important.

---

# Design rules to keep the project sane

## Rule 1

The C API must stay tiny.

## Rule 2

The Lisp side must never depend directly on SDL concepts.

## Rule 3

No widgets in C.

## Rule 4

No editor logic in C.

## Rule 5

Do not add new backend functions until the Lisp side clearly needs them.

## Rule 6

Keep the first layout engine dumb and predictable.

## Rule 7

Treat the text editor core as a separate later project, not “just another widget.”

---

# My recommended first exposed C header

This is the shape I start from conceptually:

```c
typedef struct Window Window;

typedef enum {
    EVENT_NONE = 0,
    EVENT_QUIT,
    EVENT_WINDOW_RESIZED,
    EVENT_KEY_DOWN,
    EVENT_KEY_UP,
    EVENT_MOUSE_BUTTON_DOWN,
    EVENT_MOUSE_BUTTON_UP,
    EVENT_MOUSE_MOVE
} EventType;

typedef struct {
    EventType type;
    int a;
    int b;
    int c;
    int d;
} Event;

int init(void);
void shutdown(void);
const char* last_error(void);

Window* window_create(const char* title, int width, int height);
void window_destroy(Window* window);
int window_should_close(Window* window);
void window_request_close(Window* window);
void window_get_size(Window* window, int* width, int* height);

int poll_event(Event* out_event);

void begin_frame(Window* window);
void clear(Window* window, unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void fill_rect(Window* window, int x, int y, int width, int height,
                     unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void end_frame(Window* window);

unsigned long long ticks_ms(void);
void sleep_ms(int ms);
```
