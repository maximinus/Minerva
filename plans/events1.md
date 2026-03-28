# Minerva Event Normalization and Routing Spec (Phase 1)

## Goal

Implement the first stage of Minerva’s event system.

This phase should do three things:

1. convert SDL/backend events into Minerva events
2. decide which object should handle each Minerva event
3. add a standard widget API for receiving a message/event

This phase does **not** need to:

* implement button click behaviour
* implement command dispatch
* implement global shortcuts
* implement full focus management
* implement mouse capture
* implement text editing

The goal is just to establish the event pipeline.

---

# Overview

The pipeline for this phase is:

1. SDL/backend produces a raw event
2. Minerva converts it into a Minerva event
3. Minerva decides who should handle that event
4. that widget or root/window is sent the event through a common handler function

---

# Design Principles

## 1. SDL event details must not leak upward

The rest of the Minerva GUI system should not depend directly on SDL event types, SDL constants, or SDL event structs.

All SDL events that Minerva cares about should first be converted into a small internal event format.

---

## 2. Minerva events are simple Lisp lists

A Minerva event is represented as a Lisp list containing:

* an event type symbol
* a series of keyword/value pairs as needed

Examples:

```lisp
(:mouse-move :x 120 :y 60)
(:mouse-down :button :left :x 120 :y 60)
(:mouse-up :button :left :x 120 :y 60)
(:key-down :key :escape)
(:key-up :key :escape)
(:window-resized :width 1400 :height 900)
(:quit)
```

Use this simple format consistently.

---

## 3. Routing is separate from handling

Do not mix:

* event conversion
* event routing
* event handling

These should be separate functions/phases.

This is important for testing and clarity.

---

## 4. Widgets need a message/event handler API

Widgets currently have no way to receive messages/events.

Add a generic way for widgets to receive an event.
For now, most widgets may ignore events.
That is fine.

The important part is that all widgets can be sent a Minerva event through a common API.

---

# Part 1: Minerva Event Format

## Supported event types in this phase

Implement support for these Minerva event types:

### Mouse

* `:mouse-move`
* `:mouse-down`
* `:mouse-up`

### Keyboard

* `:key-down`
* `:key-up`

### Window/application

* `:window-resized`
* `:quit`

That is enough for this phase.

---

## Event shapes

Use these shapes exactly or very close to them.

### Mouse move

```lisp
(:mouse-move :x 120 :y 60)
```

### Mouse button down

```lisp
(:mouse-down :button :left :x 120 :y 60)
```

### Mouse button up

```lisp
(:mouse-up :button :left :x 120 :y 60)
```

Allowed button values:

* `:left`
* `:middle`
* `:right`

### Key down

```lisp
(:key-down :key :escape)
```

### Key up

```lisp
(:key-up :key :escape)
```

For now, key events only need the normalized key symbol.
Modifier keys can be added later.

### Window resized

```lisp
(:window-resized :width 1400 :height 900)
```

### Quit

```lisp
(:quit)
```

---

## Unknown / ignored SDL events

If an SDL event is not one of the supported types for this phase, it should be ignored.

The SDL-to-Minerva conversion function may return:

* `nil`
  for ignored/unhandled SDL events.

That is acceptable and expected.

---

# Part 2: SDL Event → Minerva Event Conversion

## Required function

Implement a function whose job is:

* input: one raw SDL/backend event
* output: either a Minerva event list or `nil`

Suggested conceptual name:

* `sdl-event->minerva-event`

The exact function name is flexible.

---

## Behaviour

### Mouse move

Convert SDL mouse move events into:

```lisp
(:mouse-move :x <x> :y <y>)
```

### Mouse button down

Convert SDL mouse button down events into:

```lisp
(:mouse-down :button <button> :x <x> :y <y>)
```

### Mouse button up

Convert SDL mouse button up events into:

```lisp
(:mouse-up :button <button> :x <x> :y <y>)
```

Normalize SDL button values into:

* `:left`
* `:middle`
* `:right`

Ignore unsupported mouse buttons for now.

### Key down

Convert SDL key down events into:

```lisp
(:key-down :key <normalized-key>)
```

### Key up

Convert SDL key up events into:

```lisp
(:key-up :key <normalized-key>)
```

Normalize keys into Minerva-friendly symbols/keywords if possible.
Do not leak raw SDL key constants upward unless there is no practical alternative.
If only a few keys are normalized at first, that is acceptable, but do it consistently.

### Window resize

Convert SDL resize events into:

```lisp
(:window-resized :width <w> :height <h>)
```

### Quit

Convert SDL quit events into:

```lisp
(:quit)
```

---

## SDL key normalization

For this phase, only normalize a basic useful subset.

At minimum, support:

* `:escape`
* `:enter`
* `:space`
* letters if convenient
* arrow keys if convenient

If some keys are not yet normalized, it is acceptable to:

* return a fallback normalized value
* or ignore them temporarily

But the implementation should clearly separate:

* SDL key value
  from
* Minerva key symbol

---

# Part 3: Event Routing

## Goal

Given a Minerva event and the current app state, decide who should handle the event.

For this phase, use a simple routing policy.

---

## Routing categories

### Route to root/window

These events should be handled by the root/window object:

* `:window-resized`
* `:quit`

### Route by mouse position (hit test)

These events should usually be routed to the widget under the mouse:

* `:mouse-move`
* `:mouse-down`
* `:mouse-up`

### Route to focused widget

These events should be routed to the focused widget:

* `:key-down`
* `:key-up`

If there is no focused widget yet, route key events to the root/window.

---

## Required routing function

Implement a function conceptually like:

* input:

  * app state
  * Minerva event
* output:

  * the target object that should handle the event

Suggested conceptual name:

* `route-minerva-event`
* or similar

The exact name is flexible.

---

## Hit testing

This phase assumes there is or will be some way to determine which widget lies under a given mouse position.

If hit testing already exists, use it.
If not, add a simple hit-test function that:

* examines widget layout rectangles
* finds the widget under `(x,y)`
* returns the most appropriate/deepest widget

For now, a simple version is enough.

The routing code should not hardcode button knowledge or widget-specific logic.
It should just ask:

* what widget is under this point?

---

# Part 4: Widget Message/Event Handling API

## Goal

Add a standard way to send a Minerva event/message to a widget.

Widgets currently do not have this ability.
This phase should add it.

---

## Required generic handler

Add a generic function or standard dispatch function for widgets, conceptually like:

* `handle-event`
  or
* `handle-message`

The exact name is flexible.

Recommended meaning:

* input:

  * widget
  * app state or context if needed
  * Minerva event
* output:

  * for now, probably no action or a placeholder result

For this phase, it is acceptable if most widgets simply ignore events and do nothing.

The important thing is to establish the API.

---

## Default behaviour

Provide a default implementation for the base widget type that:

* accepts the event
* ignores it
* returns no actions / `nil` / no-op result

This allows the system to send events to any widget safely, even before widget-specific handling exists.

---

## Window/root behaviour

The root/window should also be able to receive events through a handler.

For now:

### `:window-resized`

The root/window handler should update the stored window size if that is how the app is structured.

### `:quit`

The root/window or app-level handler should mark the app as wanting to quit.

The exact state flag is flexible, for example:

* `should-quit`
* `running = false`
* etc.

---

# Part 5: Event Processing Flow

## Required top-level phase function

Implement a small function that processes one Minerva event through the system.

Conceptually:

1. route event
2. send event to target
3. let target ignore it or handle it

Suggested conceptual name:

* `process-minerva-event`
* or similar

Inputs:

* app state
* Minerva event

This function should:

* decide the target
* call the widget/window handler
* not yet implement full commands or action queues

---

# Part 6: App State Requirements

This phase requires app state to track at least:

* root window/root widget
* current window size
* currently focused widget id or object, if any
* running/quit flag
* enough widget tree/layout data for hit testing

If focus is not implemented yet, use a simple placeholder:

* key events go to root/window
  or
* app state stores a focus slot that may be `nil`

That is acceptable for this phase.

---

# Part 7: Suggested Initial Behaviour

For this phase, event handling can be very small.

### Mouse events

* route to widget under mouse
* widget likely ignores event for now

### Key events

* route to focused widget if present
* otherwise route to root/window
* widgets likely ignore event for now

### Resize

* route to root/window
* root/window updates size and probably marks layout/redraw as needed if such flags exist

### Quit

* route to root/window
* root/window sets quit flag

This is enough for a first implementation.

---

# Part 8: Examples

## Example 1: mouse move

Raw SDL event:

* mouse moved to `(120, 60)`

Converted Minerva event:

```lisp
(:mouse-move :x 120 :y 60)
```

Routing:

* hit-test widget tree at `(120,60)`
* find target widget, for example `:load-button`

Handling:

* send event to that widget’s event handler
* widget may ignore it for now

---

## Example 2: mouse down

Raw SDL event:

* left mouse button down at `(300, 40)`

Converted Minerva event:

```lisp
(:mouse-down :button :left :x 300 :y 40)
```

Routing:

* hit-test at `(300,40)`
* send to widget under mouse

Handling:

* widget receives event through standard widget handler

---

## Example 3: key down

Raw SDL event:

* key down Escape

Converted Minerva event:

```lisp
(:key-down :key :escape)
```

Routing:

* if focused widget exists, send there
* otherwise send to root/window

Handling:

* target receives event through standard handler

---

## Example 4: window resize

Raw SDL event:

* window resized to `1400 x 900`

Converted Minerva event:

```lisp
(:window-resized :width 1400 :height 900)
```

Routing:

* send to root/window

Handling:

* root/window updates its size state

---

## Example 5: quit

Raw SDL event:

* quit requested

Converted Minerva event:

```lisp
(:quit)
```

Routing:

* send to root/window

Handling:

* app marks quit flag

---

# Part 9: What Not To Do Yet

Do **not** implement these in this phase:

* widget-specific click logic
* command dispatch
* button activation
* mouse capture
* drag handling
* text input
* global keybindings
* bubbling/propagation
* complex focus rules

Keep this phase narrowly focused on:

* conversion
* routing
* widget event reception

---

# Part 10: Testing Requirements

This phase should be testable.

Tests should cover:

## SDL event conversion tests

* mouse move converts correctly
* left/middle/right button down convert correctly
* left/middle/right button up convert correctly
* key down/up convert correctly
* window resized converts correctly
* quit converts correctly
* ignored SDL events return `nil`

## Routing tests

* mouse events route to widget under mouse
* resize routes to root/window
* quit routes to root/window
* key events route to focused widget when one exists
* key events route to root/window when no focused widget exists

## Handler API tests

* widgets can receive an event without crashing
* default widget handler ignores events
* root/window handler updates resize or quit state correctly

Do not require visible rendering for these tests.

---

# Part 11: Summary

Implement:

## Conversion

A function that maps SDL/backend events into simple Minerva event lists.

## Routing

A function that decides where a Minerva event should go:

* root/window
* focused widget
* widget under mouse

## Handling

A widget/root event handler API so widgets can receive Minerva events, even if they ignore them for now.

This phase establishes the event pipeline and prepares the system for later phases like:

* button click handling
* focus behaviour
* commands
* menus
* editor input
