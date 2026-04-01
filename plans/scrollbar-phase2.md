Below is a focused implementation spec for `ScrollArea` Phase 2.

It assumes Phase 1 already exists and works:

* `ScrollArea` has one child
* child is measured at full size
* viewport clipping works
* horizontal and vertical scrollbars appear when needed
* scrollbar thumbs are rendered with correct size/position
* arrow buttons scroll by a fixed amount
* scroll offsets clamp correctly

This phase adds:

* thumb dragging
* mouse wheel support for vertical scrolling
* optional simple hover/pressed state for scrollbar controls if convenient

This phase still does **not** need:

* horizontal mouse wheel scrolling
* track clicks for page scrolling
* keyboard scrolling
* inertia/animated scrolling
* overlay scrollbars
* touch gestures

---

# Minerva ScrollArea — Phase 2 Spec

## Goal

Extend `ScrollArea` so the scrollbars are properly interactive.

At the end of Phase 2, the `ScrollArea` should support:

* dragging the horizontal thumb
* dragging the vertical thumb
* mouse wheel scrolling vertically
* continued arrow-button scrolling
* correct updates of thumb position while scrolling

This should make `ScrollArea` usable enough for the text editor and other large-content widgets.

---

# Part 1: New State

## Goal

The `ScrollArea` now needs to track drag state.

## Required new state

Add at least:

* `drag-mode`
* `drag-start-mouse-x`
* `drag-start-mouse-y`
* `drag-start-scroll-x`
* `drag-start-scroll-y`

### Meaning

#### `drag-mode`

Indicates what is currently being dragged.

Allowed values for this phase:

* `nil`
* `:horizontal-thumb`
* `:vertical-thumb`

#### `drag-start-mouse-x`, `drag-start-mouse-y`

Mouse position when drag began.

#### `drag-start-scroll-x`, `drag-start-scroll-y`

Scroll offsets when drag began.

These let the scroll area compute new offsets relative to the drag start.

---

# Part 2: Thumb Dragging

## Goal

The scrollbar thumb should be draggable.

For this phase:

* clicking and dragging the thumb should move the viewport proportionally
* dragging should only start if the mouse-down occurred on the thumb
* releasing the mouse should stop dragging

---

## Required behaviour: horizontal thumb

When the horizontal scrollbar is visible and the user presses the left mouse button on the horizontal thumb:

* set `drag-mode = :horizontal-thumb`
* store drag-start mouse position
* store drag-start horizontal scroll offset

While dragging:

* horizontal mouse movement should update `scroll-x`
* thumb position should update accordingly
* redraw should be requested

On mouse release:

* clear `drag-mode`

---

## Required behaviour: vertical thumb

When the vertical scrollbar is visible and the user presses the left mouse button on the vertical thumb:

* set `drag-mode = :vertical-thumb`
* store drag-start mouse position
* store drag-start vertical scroll offset

While dragging:

* vertical mouse movement should update `scroll-y`
* thumb position should update accordingly
* redraw should be requested

On mouse release:

* clear `drag-mode`

---

# Part 3: Drag Calculation

## Goal

Dragging the thumb should move the viewport proportionally through the full scroll range.

## Required rule

### Horizontal drag

The horizontal thumb moves within the horizontal track.

The mapping should be:

* thumb movement along the track corresponds proportionally to
* scroll offset movement across the full horizontal scrollable range

Conceptually:

* determine usable thumb travel distance
* determine full horizontal scroll range
* map mouse delta to thumb delta
* map thumb delta to new `scroll-x`

### Vertical drag

Same logic on the vertical axis.

---

## Important requirement

Dragging must be based on:

* total scrollable content range
* total thumb travel range

Do **not** simply add raw pixel mouse delta directly to the scroll offset unless the math happens to account for the scale correctly.

This is important.

---

# Part 4: Clamping During Drag

## Goal

Dragging must not move beyond valid bounds.

## Required rule

After computing new offsets during drag:

* clamp `scroll-x`
* clamp `scroll-y`

Then recompute thumb geometry as normal.

This ensures:

* dragging past track ends is safe
* thumb does not visually escape the track

---

# Part 5: Mouse Wheel Support

## Goal

Allow the mouse wheel to scroll vertically.

For this phase:

* only vertical wheel scrolling is needed

---

## Required behaviour

When the mouse wheel is used over the `ScrollArea`:

* adjust `scroll-y`
* clamp to valid range
* request redraw

This should work when:

* the `ScrollArea` has a vertical scrollbar
* or more generally, when vertical scrolling is possible

If vertical scrolling is not needed because content fits:

* the wheel event may be ignored

---

## Scroll amount

Use a simple fixed increment per wheel step.

A good default is:

* a small multiple of line height if known
* otherwise a fixed pixel amount like 30 or 40 px

Because `ScrollArea` is generic, a fixed pixel amount is acceptable for now.

The amount should be large enough to feel responsive but not huge.

---

## Event consumption

If the mouse wheel changes `scroll-y`, the event should count as handled.

If the `ScrollArea` cannot scroll vertically, the event may be passed onward according to normal routing rules.

That is acceptable.

---

# Part 6: Event Handling

## Goal

Extend `ScrollArea` event handling to cover dragging and wheel scrolling.

## Required event types

Handle at least:

* `:mouse-down`
* `:mouse-up`
* `:mouse-move`
* `:mouse-wheel`

If your system represents wheel differently, adapt accordingly, but keep the semantics clear.

---

## Mouse-down behaviour

Priority order inside `ScrollArea` should now be:

1. arrow buttons
2. scrollbar thumbs
3. viewport/content area

### If mouse-down is on arrow button

Existing Phase 1 behaviour applies.

### If mouse-down is on thumb

Begin thumb drag.

### If mouse-down is elsewhere

No drag starts.
Track clicks still do nothing in Phase 2 unless added deliberately.

---

## Mouse-move behaviour

If `drag-mode` is active:

* update the corresponding scroll offset
* request redraw
* treat the event as handled

If not dragging:

* no special behaviour required for this phase
* optional hover state support is allowed but not required

---

## Mouse-up behaviour

If dragging is active:

* stop dragging
* clear drag state
* event handled

Otherwise:

* normal behaviour as before

---

## Mouse-wheel behaviour

If wheel occurs over the `ScrollArea` and vertical scrolling is possible:

* update `scroll-y`
* clamp
* request redraw
* event handled

---

# Part 7: Thumb Hit Testing

## Goal

The scroll area must be able to tell whether the mouse is on the thumb.

## Required behaviour

Use the computed thumb rects from Phase 1.

If mouse-down is inside:

* horizontal thumb rect → begin horizontal drag
* vertical thumb rect → begin vertical drag

This should be explicit and testable.

---

# Part 8: Child Event Forwarding

## Goal

The `ScrollArea` must still allow events to reach its child when appropriate.

## Required rule

If an event is not handled by:

* scrollbar buttons
* scrollbar thumbs
* wheel scrolling logic

then it may be passed to the child/content area as appropriate.

Examples:

* click inside viewport but not on scrollbars → child may receive it
* mouse move while not dragging → child may receive it

This keeps `ScrollArea` reusable as a wrapper around interactive widgets.

---

# Part 9: Recalculation Rules

## Goal

Dragging and wheel scrolling change viewport offsets but not content size.

## Required behaviour

After drag or wheel change:

* update scroll offset
* clamp it
* recompute thumb positions if needed
* request redraw

Full child remeasurement is not required unless something else changed.

This keeps the interaction cheap.

---

# Part 10: Manual Test Scenarios

These should work at the end of Phase 2.

## 1. Drag vertical thumb

* create content taller than viewport
* press on vertical thumb
* drag it downward
* content scrolls downward
* thumb tracks movement correctly

## 2. Drag horizontal thumb

* create content wider than viewport
* press on horizontal thumb
* drag it right
* content scrolls right
* thumb tracks movement correctly

## 3. Release stops dragging

* begin thumb drag
* release mouse
* moving mouse no longer changes scroll offset

## 4. Wheel scrolls vertically

* place mouse over scroll area
* use mouse wheel
* content scrolls vertically

## 5. Arrow buttons still work

* click scrollbar arrows
* offsets change correctly

## 6. Child still receives clicks in viewport

* click inside visible child area, not on scrollbar
* child interaction still works

---

# Part 11: Automated Test Requirements

## Drag state tests

### 1. Mouse-down on horizontal thumb starts horizontal drag

Assert:

* `drag-mode = :horizontal-thumb`

### 2. Mouse-down on vertical thumb starts vertical drag

Assert:

* `drag-mode = :vertical-thumb`

### 3. Mouse-up clears drag mode

Assert drag state resets.

---

## Drag behaviour tests

### 4. Horizontal drag updates `scroll-x`

Simulate drag movement.
Assert `scroll-x` changes proportionally and clamps correctly.

### 5. Vertical drag updates `scroll-y`

Simulate drag movement.
Assert `scroll-y` changes proportionally and clamps correctly.

### 6. Dragging past bounds clamps offsets

Simulate over-drag.
Assert offsets remain valid.

### 7. Thumb position updates after drag

Assert thumb rect changes consistently with offsets.

---

## Mouse wheel tests

### 8. Wheel changes `scroll-y` when vertical scrolling is possible

Assert vertical offset changes.

### 9. Wheel does nothing when content fits vertically

Assert no scroll change and optionally event not handled.

### 10. Wheel scrolling clamps properly at top and bottom

Assert no invalid offsets.

---

## Existing behaviour regression tests

### 11. Arrow buttons still change offsets correctly

Assert Phase 1 behaviour still works.

### 12. Thumb size is unchanged by drag logic

Assert thumb size remains tied to visible fraction, not drag state.

### 13. Child viewport clipping still works after scroll changes

Assert visible region updates correctly.

---

# Part 12: Example Behaviour

## Example 1: Vertical drag

Content height: 1000 px
Viewport height: 250 px

User drags vertical thumb halfway down the track.

Expected:

* `scroll-y` becomes approximately halfway through the valid vertical scroll range
* content shown is approximately the middle region

## Example 2: Wheel

Content height larger than viewport.
User scrolls wheel downward twice.

Expected:

* `scroll-y` increases by two fixed increments
* thumb moves downward accordingly

## Example 3: Drag release

User presses thumb, drags, then releases.
Further mouse movement should not affect `scroll-x` or `scroll-y`.

---

# Part 13: Out of Scope for Phase 2

Do **not** add yet:

* track click page scrolling
* horizontal wheel support
* shift+wheel semantics
* animated thumb movement
* inertial scrolling
* keyboard scrolling
* auto-repeat on held arrow buttons
* sophisticated hover/pressed skin states unless trivial

Keep this phase focused on:

* thumb dragging
* vertical mouse wheel scrolling
* preserving the Phase 1 behaviour

---

# Part 14: Summary

Implement `ScrollArea` Phase 2 with:

* horizontal and vertical thumb dragging
* vertical mouse wheel scrolling
* correct proportional mapping between thumb movement and scroll offsets
* proper drag state tracking
* clamping and redraw updates
* continued forwarding of non-scrollbar events to the child when appropriate

At the end of this phase, `ScrollArea` should feel like a genuinely usable generic scroll container.
