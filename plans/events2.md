Below is a focused implementation spec for the next phase.

It assumes Phase 1 already exists:

* SDL/backend events are converted into Minerva events
* Minerva events are routed
* widgets can receive events through a common handler API
* root/window can handle resize and quit

This phase adds:

* a real `Button` widget interaction model
* button state changes for hover/press
* activation on click
* a first action/command emission path
* a minimal action-processing phase

It does **not** yet implement a full command system across the whole app. It just establishes the pattern.

---

# Minerva Button Interaction and Action Emission Spec (Phase 2)

## Goal

Implement the first real interactive widget in Minerva: a `Button`.

This phase should allow a button to:

* detect hover from mouse movement
* become pressed on mouse down
* activate on mouse up when appropriate
* emit a simple action representing what should happen
* update app/UI state as needed for redraw

This phase should also add the first minimal action-processing layer so that button activation can trigger named behaviour in a simple, explicit way.

The architecture should remain:

* easy to understand
* easy to test
* suitable for gradual extension

---

# Overview

The event flow for this phase should be:

1. SDL event becomes a Minerva event
2. Minerva routes that event to a widget
3. the button receives the event
4. the button may update its local state
5. the button may emit an action such as:

   ```lisp
   (:command :load-file)
   ```
6. Minerva processes that action through a simple dispatcher

This phase introduces the idea that widgets emit actions instead of directly performing arbitrary application logic.

---

# Design Principles

## 1. Buttons should emit actions, not do arbitrary work directly

A button should not itself implement:

* file loading
* buffer saving
* pane splitting
* quitting the app

Instead, it should emit an action or command name.

Example:

* button id: `:load-button`
* command: `:load-file`

When activated, the button emits:

```lisp
(:command :load-file)
```

This keeps widgets simple and makes behaviour reusable.

---

## 2. Button interaction state belongs to the button

A button should track enough state to support interaction.

For this phase, a button should know whether it is:

* normal
* hovered
* pressed

The exact representation is flexible:

* separate booleans
* a single state slot like `:normal`, `:hover`, `:pressed`
* another simple representation

Choose a representation that is easy to inspect and test.

---

## 3. Activation happens on press + release inside the same button

Use the standard GUI button rule:

* mouse-down inside button → button becomes pressed
* mouse-up inside button after that press → button activates
* if mouse-up occurs elsewhere, button does not activate

This is the minimum useful click model.

---

## 4. Keep the action system tiny in this phase

Do not build a full command palette, keybinding framework, or giant dispatcher yet.

This phase only needs:

* widgets can return actions
* app can process those actions
* a small number of commands can be handled explicitly

This is enough to establish the pattern.

---

# Part 1: Button Widget

## Required widget type

Check the current `Button` widget fits this model.

---

## Required properties

A button should have at least:

* `label` or some display text
* `command`
* interaction state
* normal widget layout properties

### Meaning of properties

#### `label`

Display text, for example `"Load"`

#### `command`

The command or action name to emit when activated, for example:

* `:load-file`
* `:save-current-buffer`

#### interaction state

* normal
* hovered
* pressed

---

# Part 2: Button Minimum Size

## Goal

The button should participate in layout like any other widget.

For this phase, keep minimum size rules simple.

### Acceptable options

Either:

1. use a fixed minimum size for all buttons in this phase
2. compute a minimum size from label text if text measurement is already available

Either is acceptable.

If text measurement is not yet ready or would complicate this phase too much, use a fixed minimum size.

Example:

* minimum width 80
* minimum height 30

The important part is that layout works and the button has a rectangle.

---

# Part 3: Button Rendering

## Goal

The button must visibly reflect its interaction state.

For this phase, keep rendering simple.

The button can render as:

* a rectangle background
* with different colors depending on state
* optional text label if text rendering is already easy to use

### Minimum visual behaviour

Use different colors for:

* normal
* hovered
* pressed

This is enough for the first interactive milestone.

If labels are already easy to draw, include them. If not, it is acceptable to leave label rendering basic or temporary.

---

# Part 4: Button Event Handling

## Goal

Buttons must respond to Minerva mouse events.

For this phase, handle:

* `:mouse-move`
* `:mouse-down`
* `:mouse-up`

You may also optionally handle key activation later, but it is not required in this phase.

---

## 4.1 Mouse move behaviour

When the button receives a `:mouse-move` event:

* if the mouse is inside the button rect and the button is not pressed, set state to hovered
* if the mouse is outside the button rect and the button is not pressed, set state to normal

If the button is pressed, you may either:

* keep it pressed until mouse-up
  or
* optionally track whether the release should still count as activation

For this phase, the simplest acceptable rule is:

* pressed state remains pressed until mouse-up

That is fine.

If the visual hover/pressed distinction while dragging becomes important later, it can be refined in a later phase.

---

## 4.2 Mouse down behaviour

When the button receives:

```lisp
(:mouse-down :button :left :x ... :y ...)
```

and the event is inside the button:

* set button state to pressed

It should also become the active/captured button for the current click sequence.

This phase needs a minimal way to remember:

* which button was pressed on mouse-down

The exact storage can be:

* in app state
* in the root/window
* or another small central place

Do not implement a full general mouse capture system yet, but do add enough state to remember the currently pressed button id or object.

Suggested name conceptually:

* `active-widget`
  or
* `pressed-widget`

---

## 4.3 Mouse up behaviour

When the left mouse button is released:

If:

* this button was previously the active/pressed button
* and the mouse-up occurs inside this button

then:

* the button activates
* the button emits its action:

  ```lisp
  (:command <button-command>)
  ```

After mouse-up:

* clear the active/pressed tracking
* update button state back to hovered if mouse is still inside
* otherwise set to normal

If mouse-up occurs outside the button:

* do not activate
* clear pressed state
* return to normal

---

# Part 5: Active/Pressed Widget Tracking

## Goal

The system needs a minimal way to remember which widget started the click.

This is required so a button can activate on mouse-up only if it was the one originally pressed.

## Required app state addition

Add one slot to app state, root, or UI controller state:

* currently active/pressed widget id or object
* or `nil` if none

This is only for this phase’s simple click tracking.

You do **not** need to build a full drag/capture framework yet.

---

# Part 6: Widget Event Handler Return Value

## Goal

Widgets should now be able to return actions from event handling.

In Phase 1, widgets could ignore events.
Now buttons need to emit something.

## Required change

The widget event handler API should now support returning:

* `nil` for no action
* or one action
* or a list of actions

Choose one consistent convention.

Recommended simple choice:

* return a list of actions
* return `nil` or empty list if no action

This scales nicely.

### Example

A button click may return:

```lisp
((:command :load-file))
```

or a single action if you prefer a single-action convention.
Just be consistent.

---

# Part 7: Action Processing

## Goal

Introduce the first action-processing phase.

This phase does not need a giant framework.

It only needs enough to:

* receive widget-emitted actions
* process `:command` actions
* maybe process a few UI-state actions if needed

---

## Required top-level action processing function

Implement a function conceptually like:

* input:

  * app state
  * action or list of actions
* output:

  * updated state and/or side effects

Suggested conceptual name:

* `process-action`
* `process-actions`

---

## Required action type in this phase

Support at minimum:

```lisp
(:command <command-name>)
```

That is enough.

---

## Required command handling in this phase

For now, commands can be handled by a very small explicit dispatcher.

Example:

* if command is `:load-file`, call a placeholder or test function
* if command is `:quit-app`, set quit flag
* etc.

Do not build a big registry yet unless it is easy.

This phase is about proving the path:

* button click
* emits command
* command is processed centrally

---

# Part 8: Example Button Flow

## Example setup

Create a button with:

* id `:load-button`
* label `"Load"`
* command `:load-file`

It has a layout rectangle on screen, for example:

* x 10
* y 10
* width 80
* height 30

---

## Example click sequence

### Step 1: mouse down

Minerva event:

```lisp
(:mouse-down :button :left :x 20 :y 20)
```

Routing:

* event goes to `:load-button`

Button handling:

* point is inside button
* button state becomes pressed
* app state records active widget = `:load-button`
* no command emitted yet

### Step 2: mouse up

Minerva event:

```lisp
(:mouse-up :button :left :x 20 :y 20)
```

Routing:

* this phase may route by hit test as before, but logic must still be able to check the active widget
* or if your routing already supports sending mouse-up to the active widget, use that

Button handling:

* button sees it was the active pressed widget
* point is still inside button
* button returns:

  ```lisp
  ((:command :load-file))
  ```
* button state becomes hovered
* active widget is cleared

### Step 3: action processing

Action processing sees:

```lisp
(:command :load-file)
```

It dispatches that command centrally.

This proves the full path.

---

# Part 9: Routing Adjustments for This Phase

## Goal

Phase 1 routed mouse events to the widget under the mouse.

For buttons, this is almost enough, but mouse-up handling now needs one small refinement.

## Required behaviour

For `:mouse-up`, if there is an active/pressed widget recorded, the event should be deliverable to that widget.

This can be done in either of two acceptable ways:

### Option A

Special-case mouse-up routing:

* if active widget exists, send mouse-up there

### Option B

Still route by hit test, but ensure button activation logic can inspect active widget state centrally

Option A is usually simpler and more standard.
It more closely matches real mouse capture.

For this phase, Option A is recommended.

---

# Part 10: Redraw Behaviour

## Goal

Button state changes must be visible.

Whenever a button changes visual state:

* normal → hovered
* hovered → pressed
* pressed → hovered
* pressed → normal

the UI should be marked for redraw.

## Required behaviour

When button interaction state changes:

* set `needs-redraw = true`

If layout does not change, no relayout is needed.

So:

* button state changes require redraw
* not relayout

---

# Part 11: Tests

This phase should be testable without relying on manual visual inspection.

## Required test categories

### 1. Button initial state

Create a button.
Assert that its initial state is normal.

### 2. Mouse move inside button sets hovered state

Send a `:mouse-move` inside the button.
Assert that state becomes hovered.

### 3. Mouse move outside button keeps/returns normal state

Send a `:mouse-move` outside the button.
Assert that state is normal.

### 4. Mouse down inside button sets pressed state

Send `:mouse-down` inside button.
Assert:

* state becomes pressed
* active widget is set

### 5. Mouse up inside same button emits command

Perform:

* mouse-down inside
* mouse-up inside

Assert:

* button emits `(:command <button-command>)`
* active widget is cleared
* state becomes hovered or normal as appropriate

### 6. Mouse down inside, mouse up outside does not activate

Perform:

* mouse-down inside
* mouse-up outside

Assert:

* no command emitted
* active widget cleared
* button state returns to normal

### 7. Action processor handles command centrally

Feed a `(:command :load-file)` action into the action processor.
Assert that the central command logic runs.

For testing, this could set a flag or record that the command was invoked.

### 8. Button state changes request redraw

Assert that hover/press/release transitions set redraw flag.

---

# Part 12: What Not To Do Yet

Do **not** implement these in this phase unless they come almost for free:

* keyboard activation for buttons
* disabled buttons
* double-click logic
* drag-outside / drag-back-inside pressed visuals
* general mouse capture system
* full command registry
* menu logic
* global shortcuts
* focus traversal
* button label text measurement if it complicates the phase too much

Keep this phase narrowly about:

* button interaction
* action emission
* minimal action handling

---

# Part 13: Summary

Implement the following:

## New widget

* `Button`

## New button behaviour

* normal / hovered / pressed state
* reacts to mouse move, mouse down, mouse up
* activates on press+release inside

## New app/UI state

* currently active/pressed widget

## Updated widget event handling

* widgets may now return actions

## New action processing phase

* supports at least `(:command <name>)`

## Minor routing improvement

* mouse-up should be deliverable to the active widget

This phase should end with a working button interaction path:

* mouse click on button
* button emits command action
* command processed centrally

That is the first real interactive milestone for Minerva.

---

If you want, I can next write the following phase in the same style: adding keyboard focus and letting buttons activate on Enter/Space, while laying the groundwork for editor widgets to receive keyboard input.
