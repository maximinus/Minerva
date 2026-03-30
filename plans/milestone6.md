Below is a focused implementation spec for the next phase.

It assumes the following already exist:

* root window/base UI tree
* layout engine
* event normalization and routing
* widget event handlers
* buttons and menus
* command/action emission
* rendering of widgets into the window

This phase adds:

* overlay/layer support
* floating UI elements such as menus
* topmost-first input handling
* overlay anchoring
* overlay dismissal rules
* focus/input priority for overlays

This phase does **not** add:

* submenu trees
* complex popup placement heuristics
* full modal dialog system
* animated overlays
* drag-and-drop across layers
* multi-window overlay support

The goal is to add a simple and robust overlay stack suitable for menus and future floating UI.

---

# Minerva Overlay / Layer Stack Spec (Phase: Floating UI)

## Goal

Add support for floating UI elements that are not constrained to live inside the normal base window layout tree.

Examples include:

* drop-down menus
* popup menus
* command palette later
* dialogs later
* tooltips later
* autocomplete popups later

The system should support:

* rendering overlays above the base UI
* routing input to overlays before the base UI
* dismissing overlays on outside click or Escape
* anchoring overlays relative to some widget or rectangle
* optionally giving overlays keyboard focus priority

---

# Core Design

## Two UI regions

Minerva should now conceptually have:

### 1. Base UI

The normal root widget tree that fills the window and is laid out inside the window rectangle.

Examples:

* editor panes
* terminal pane
* toolbars
* menu bar later
* sidebars
* status bar

### 2. Overlay stack

A stack of floating UI elements rendered above the base UI.

Examples:

* a menu opened from a menu bar item
* a context menu
* a command palette later

The overlay stack is ordered:

* oldest overlay at the bottom
* newest overlay at the top

---

# Part 1: Overlay Object

## Required new concept

Add an `Overlay` or similarly named object.

This object represents one floating UI layer.

An overlay is not just a render layer.
It also has input and dismissal behaviour.

---

## Required properties

Each overlay should have at least:

* `root-widget`
* `position`
* `capture-all`
* `focus`

Optional but useful:

* previous focus info for restoration later
* whether the overlay is modal-like
* whether outside click is consumed

---

## Meaning of properties

### `root-widget`

The widget tree or root widget for this overlay.
For example:

* a `Menu`
* later a dialog widget
* later a command palette widget

### `position`

The final resolved position where the overlay is placed in window coordinates.

## `capture-all`

If true, all events are passed to the overlay; if false, only events over the widget are passed to the widget
(in that latter case, the events NOT over the widget are passed to the next overlay)

### `focus`

An enum with possible values:

* capture
    All events are captured and not passed to other overlays or root window
* pass-through
    Events can be passed through (they may be captured, depends on the overlay widget)
* ignore
    All events are ignored and are passed straight through to the next overlay / root window

---

# Part 2: Overlay Stack in App State

## Required app state addition

Add an overlay stack to the application state.

Suggested conceptual field:

* `overlay-stack`

This should be an ordered collection, for example:

* list
* vector
* stack-like list with newest at head

Choose a representation that makes:

* pushing overlays
* popping overlays
* iterating top-to-bottom and bottom-to-top

easy and clear.

---

## Required operations

Implement operations conceptually like:

* `push-overlay`
* `pop-overlay`
* `remove-overlay`
* `top-overlay`
* `overlay-stack-empty-p`

Exact names are flexible.

These should update app state consistently.

---

# Part 3: Rendering Rules

## Goal

Overlays must appear above the base UI.

## Required rendering order

Rendering should happen in this order:

1. render base UI first
2. render overlays from oldest to newest

This ensures:

* newer overlays appear on top of older overlays
* all overlays appear above the base UI

---

## Overlay rendering behaviour

Each overlay renders its own root widget in its resolved rectangle.

Do not insert overlays into the base layout tree.
They are rendered separately after base UI rendering.

This is important.

---

# Part 4: Input Routing Rules

## Goal

Overlays should get first chance to handle events.

## Required routing order

For input events:

1. start with the newest overlay
2. work downward through older overlays
3. if no overlay handles the event, route to the base UI

This is the core routing rule for this phase.

---

## Event categories

These routing rules should apply to:

* mouse move
* mouse down
* mouse up
* key down
* key up
* text input later if already present
* Escape handling

Resize and quit remain top-level/root events.

---

## Determining “outside”

A click is outside the overlay if it is not inside the overlay’s active widget area / root widget rectangle.

For this phase, it is acceptable to use the overlay rect as the test.
If your widget hit-testing system already gives a better answer, that is also acceptable.

---

# Part 5: Overlay Layout

## Goal

Overlay layout should be separate from base layout.

## Required rule

Do not place overlays inside the base HBox/VBox tree.

Instead:

1. layout base UI normally
2. resolve/layout each overlay separately using:

   * its position
   * its root widget’s size requirements

This keeps overlays independent and simple.

---

# Part 6: Overlay Event Handling Model

## Goal

An overlay should behave like a mini-root for its widget tree.

## Required behaviour

When an overlay receives an event:

* it routes the event inside its own widget tree using normal widget routing/hit testing rules
* its root widget handles or delegates as appropriate

This means overlays reuse the existing event/widget system instead of inventing a new one.

---

# Part 7: Focus Restoration

## Goal

When an overlay closes, the underlying UI should continue working.

## Required first-pass behaviour

For this phase, it is acceptable to do something simple:

* when overlay closes, remove it from the overlay stack
* keyboard routing falls back to the next overlay or base UI automatically

You do not yet need a sophisticated “restore previous exact focused widget” mechanism unless it is easy.

However, the design should not prevent that from being added later.

---

# Part 8: Menu Use Case

## Example scenario

The user clicks a menu-bar button later or some button that opens a menu.

The system should be able to:

1. create a `Menu` widget
2. wrap it in an overlay
3. place it below the clicked widget (computed by the menu-bar)
4. push it on the overlay stack
5. render it above the base UI
6. send input to it first
7. close it on outside click or Escape

This is the primary motivating use case for this phase.

---

# Part 9: Tests

This phase should be testable without relying only on manual visual inspection.

## Overlay stack tests

### 1. Pushing an overlay adds it above existing overlays

Assert stack order is correct.

### 2. Popping/removing overlay updates stack correctly

Assert top overlay changes as expected.

---

## Rendering order tests

### 3. Base UI renders before overlays

Assert rendering order is base first, overlays later.

### 4. Older overlays render before newer overlays

Assert top overlay is drawn last.

---

## Input routing tests

### 5. Mouse events go to newest overlay first

Create two overlapping overlays.
Assert mouse event is routed to the newest/topmost one first.

### 6. If top overlay does not handle and does not block, lower layer can receive event

Assert lower overlay or base UI can receive event when appropriate.

### 7. If top overlay blocks lower input, lower layers do not receive event

Assert propagation stops.

---

## Anchor/layout tests

### 8. Overlay anchored below a rect appears below it

Assert computed overlay rect is placed correctly.


### 9. Overlay layout is independent of base layout tree

Assert overlay can be placed outside the main base layout flow.

---

## Menu integration tests

### 10. A menu opened as overlay renders above base UI

Assert correct stacking.

---

# Part 10: Out of Scope for This Phase

Do **not** implement yet:

* submenu chaining
* advanced placement flipping
* dimmed modal backdrops
* keyboard navigation inside overlays
* drag interactions across overlays
* tooltip-specific behaviour
* per-pixel hit testing for overlays
* multi-window overlays
* animation/transitions

Keep this phase focused on:

* overlay stack
* rendering order
* input priority
* position placement

---

# Part 11: Summary

Implement:

## New concept

* `Overlay` object with rendering, input, and dismissal policy

## New app state

* overlay stack

## New rules

* render base UI first, overlays oldest-to-newest
* route input newest overlay to oldest, then base UI
* overlays can take focus and block lower input

## New placement support

* position-based overlay placement

This phase should result in a working floating menu/menu-like overlay system that can later support:

* menu bars
* command palette
* dialogs
* tooltips
* autocomplete popups
