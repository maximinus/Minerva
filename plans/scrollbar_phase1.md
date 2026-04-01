# Minerva ScrollArea — Phase 1 Spec

## Goal

Implement a reusable `ScrollArea` widget.

A `ScrollArea` has exactly one child widget. If the child’s full size is larger than the visible area, scrollbars appear:

* horizontal scrollbar at the bottom
* vertical scrollbar at the right

For Phase 1, the scrollbars only need:

* arrow buttons at each end
* a thumb/bar showing the visible fraction
* clicking the arrow buttons to move the viewport

This phase does **not** need:

* thumb dragging
* track clicks
* mouse wheel scrolling
* keyboard scrolling
* fancy hover/pressed states
* animated scrolling

---

# Core Behaviour

## Basic idea

The child has a full content size.
The `ScrollArea` shows only a viewport onto that child.

If the child fits, no scrollbars are shown.
If the child is too wide and/or too tall, the relevant scrollbars appear.

---

# Part 1: Widget

## Required widget

Add a `ScrollArea` widget.

It should:

* participate in normal layout
* render itself and its child
* receive Minerva events
* support exactly one child

If there is no child, it behaves as empty and shows no scrollbars.

---

# Part 2: Child Size Rule

## Required rule

The child is measured at its full natural/minimum size.

That full size is treated as the scrollable content size.

The `ScrollArea` does **not** force the child to shrink to the visible viewport.

This is important.

---

# Part 3: State

The `ScrollArea` should store at least:

* child
* `scroll-x`
* `scroll-y`
* child full width
* child full height
* whether horizontal bar is visible
* whether vertical bar is visible

### Meaning

#### `scroll-x`

Horizontal viewport offset in pixels.

#### `scroll-y`

Vertical viewport offset in pixels.

Both offsets must be clamped to valid ranges.

---

# Part 4: Scrollbar Visibility

## Required rules

### Horizontal bar

Visible if:

* child full width > viewport width

### Vertical bar

Visible if:

* child full height > viewport height

Because one scrollbar reduces viewport space, use a simple two-pass or stable recalculation:

1. start with no bars
2. check whether bars are needed
3. if a bar appears, recompute viewport
4. re-check if necessary

That is enough.

---

# Part 5: Geometry

Inside the `ScrollArea` rectangle, define:

* content viewport area
* optional horizontal scrollbar at the bottom
* optional vertical scrollbar at the right
* optional bottom-right corner area if both bars are visible

Use a fixed scrollbar thickness for Phase 1.
A small constant is fine, for example 12 px.

---

# Part 6: Scrollbar Structure

## Horizontal scrollbar

Contains:

* left arrow button
* right arrow button
* track area in the middle
* thumb in the middle track

## Vertical scrollbar

Contains:

* top arrow button
* bottom arrow button
* track area in the middle
* thumb in the middle track

For Phase 1:

* the thumb is only visual
* it does not need to be draggable yet

---

# Part 7: Visual Assets

Use the provided image assets for:

* scrollbar ends
* scrollbar buttons
* thumb/bar parts

To render the bar, use the provided left/right bar images (they are 10x20 for the x bar, 20x10 for the y bar), and connect by rendering a rect of color (32, 32, 32) to join them.

Button images are provided also: they all exist in /assets/scrollbar. The buttons are all of size 20x20.

For Phase 1, it is enough that:

* the scrollbars are clearly visible
* the thumb size reflects the visible fraction
* the buttons are rendered at the ends

---

# Part 8: Thumb Size

## Required rule

### Horizontal thumb width

Proportional to:

* viewport width / child full width

### Vertical thumb height

Proportional to:

* viewport height / child full height

Use a minimum thumb size so it never becomes too small.
A small constant is fine.

---

# Part 9: Thumb Position

## Required rule

### Horizontal thumb position

Proportional to:

* `scroll-x / (child-width - viewport-width)`

### Vertical thumb position

Proportional to:

* `scroll-y / (child-height - viewport-height)`

If the content fits on an axis, that scrollbar does not exist.

---

# Part 10: Arrow Button Behaviour

## Required behaviour

### Horizontal bar

* left button decreases `scroll-x`
* right button increases `scroll-x`

### Vertical bar

* top button decreases `scroll-y`
* bottom button increases `scroll-y`

## Scroll amount

For Phase 1, use a simple fixed pixel increment.
A value like 16 px or 20 px is fine.

Track clicks do nothing in this phase.

---

# Part 11: Child Rendering

## Required behaviour

The child is rendered at full size, but shifted by:

* `-scroll-x`
* `-scroll-y`

Rendering must be clipped to the viewport rectangle.

Only the visible part of the child should appear.

This is the core behaviour of the `ScrollArea`.

---

# Part 12: Event Handling

## Required events

For Phase 1, handle:

* mouse down
* mouse up if your button logic needs it

The `ScrollArea` only needs to react to clicks on the scrollbar arrow buttons.

If a mouse event occurs in the viewport and not on scrollbar controls, it may be passed to the child.

That is acceptable.

---

# Part 13: Clamping

## Required rule

Clamp:

* `scroll-x` to `[0, max(0, child-width - viewport-width)]`
* `scroll-y` to `[0, max(0, child-height - viewport-height)]`

Do this whenever:

* the child size changes
* the `ScrollArea` size changes
* an arrow button scrolls

---

# Part 14: Recalculation

Whenever:

* the child changes size
* the `ScrollArea` is resized

the widget should:

1. measure child full size
2. determine scrollbar visibility
3. compute viewport rect
4. compute scrollbar geometry
5. clamp scroll offsets
6. compute thumb geometry

---

# Part 15: Manual Tests

## 1. Child fits fully

* child smaller than `ScrollArea`
* no scrollbars shown

## 2. Child too wide

* horizontal bar appears
* arrow buttons move content left/right

## 3. Child too tall

* vertical bar appears
* arrow buttons move content up/down

## 4. Child too wide and tall

* both bars appear
* both sets of buttons work

## 5. Thumb reflects visible amount

* if half the content is visible, thumb takes about half the track

---

# Part 16: Automated Tests

## Geometry tests

### 1. No bars when child fits

Assert both hidden.

### 2. Horizontal bar appears when child too wide

Assert horizontal visible.

### 3. Vertical bar appears when child too tall

Assert vertical visible.

### 4. Both bars appear when both axes overflow

Assert both visible.

### 5. Showing one bar may force the other

Assert stable correct result.

## Scroll tests

### 6. Left button decreases `scroll-x`

Assert movement and clamping.

### 7. Right button increases `scroll-x`

Assert movement and clamping.

### 8. Top button decreases `scroll-y`

Assert movement and clamping.

### 9. Bottom button increases `scroll-y`

Assert movement and clamping.

### 10. Scroll offsets clamp correctly

Assert bounds after repeated clicks.

## Thumb tests

### 11. Thumb size reflects visible fraction

Assert proportional size.

### 12. Thumb position reflects scroll offset

Assert proportional position.

## Rendering logic tests

### 13. Child is rendered offset by scroll position

Assert correct shifted draw position.

### 14. Child is clipped to viewport

Assert only visible portion is drawn.

---

# Part 17: Out of Scope for Phase 1

Do not add yet:

* thumb dragging
* track clicks
* wheel scrolling
* keyboard scrolling
* fancy states
* auto-scroll to child/caret
* overlay scrollbars

Keep this phase focused on:

* reusable scroll container
* viewport clipping
* scrollbar visibility
* arrow-button scrolling
* visual thumb geometry

---

# Part 18: Summary

Implement a simple reusable `ScrollArea` with:

* one child
* child measured at full size
* visible viewport
* horizontal/vertical scrollbars when needed
* end buttons that scroll by a fixed amount
* visual thumb showing visible fraction
* clipped child rendering

This is enough to establish the reusable scroll container before adding dragging and richer behaviour later.
