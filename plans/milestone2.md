# Lisp GUI Layout Engine v1 Design

## Goal

Implement the first version of a GUI/layout system in Lisp.

In this milestone, we do **NOT** want to render anything; we will build the GUI and then we can test by checking the sizes of objects in the layout we generate.

This system does **not** yet need real interactivity beyond layout and rendering of simple rectangles. The purpose is to create a testable layout engine and a minimal rendering model that can later support a text editor.

The native backend already exists and provides:

* window creation
* frame begin/end
* rectangle drawing
* event loop

This work is purely the Lisp-side GUI model.

The system should support exactly these first five widget types:

* `Window`
* `HBox`
* `VBox`
* `ColorRect`
* `Filler`

The name `Filler` is acceptable for now. It is an invisible widget used to absorb extra space during layout.

---

# Core Design Principles

## 1. GUI is a tree

The GUI is a tree of widgets.

* `Window` is the root, and has a fixed size (which is the size of the window)
* `Window` has exactly one child
* `HBox` and `VBox` are containers
* `ColorRect` and `Filler` are leaves

Each widget is responsible for:

* reporting its minimum size
* participating in layout
* rendering itself when given a final rectangle

---

## 2. Layout and rendering are separate

Layout happens first.
Rendering happens second.

A widget does **not** decide its own final position in the tree.
That is the job of its parent container.

A widget does **not** receive “available space” and then decide where to put itself.
Instead, the parent computes a **final rectangle** for the child, and the child renders inside that rectangle.

So the flow is:

1. ask widgets for size requirements
2. parent computes final child rectangles
3. render tree using those rectangles

This is important because it makes layout testable without rendering.

---

## 3. Minimum size only, no preferred size

Each widget has:

* minimum width
* minimum height

There is no preferred width/height in v1.

A widget may also declare:

* expand horizontally
* expand vertically

Meaning:

* minimum size is the least space it requires
* if expansion is enabled on an axis, the container may allocate extra space on that axis

This is enough for v1.

---

## 4. Containers control child placement

A child widget does not decide how it is positioned relative to siblings.

For example, in an `HBox`:

* the `HBox` decides child x positions
* the `HBox` decides each child’s final width
* the `HBox` decides each child’s final y position
* the `HBox` decides each child’s final height

Likewise, `VBox` controls all child placement inside itself.

A child is only given its final rectangle:

* `x`
* `y`
* `width`
* `height`

and renders inside that.

---

## 5. Non-expanding widgets keep their requested size

If a widget does **not** expand on an axis, then on that axis it should be given exactly its minimum size.

Example:

* widget has `min-height = 100`
* widget has `expand-y = false`
* parent has 300 px available height

Then the widget should still get height 100, not 300.

The parent may place it within a larger available area according to alignment rules.

This is a key rule.

---

# Widget Types

## 1. Window

### Purpose

Root container representing the whole GUI.

### Properties

* `width`
* `height`
* `child`

The window itself is not laid out by anything else.
It simply provides the root rectangle:

* `x = 0`
* `y = 0`
* `width = window width`
* `height = window height`

### Rules

* must have exactly one child
* passes its full rectangle to layout of its child
* does not use margin
* does not use alignment
* does not render anything itself in v1

---

## 2. HBox

### Purpose

Container that lays out children horizontally from left to right.

### Properties

* `children`
* `padding-left`
* `padding-right`
* `padding-top`
* `padding-bottom`
* `spacing`
* `align-y`

### Meaning of `align-y`

This is the cross-axis alignment for children inside the `HBox`.

Allowed values:

* `:start`
* `:center`
* `:end`

`HBox` does **not** need a `:stretch` alignment because vertical stretching is controlled by each child’s `expand-y` flag.

### Minimum size calculation

Given child minimum sizes and spacing/padding:

* `min-width`
  = left padding

  * right padding
  * sum of child widths
  * spacing between children

* `min-height`
  = top padding

  * bottom padding
  * maximum child minimum height

### Layout rules

Given a final rectangle for the `HBox`:

1. Compute inner rectangle by subtracting padding.
2. Determine each child’s width:

   * start with child minimum width
   * compute leftover horizontal space
   * distribute leftover equally among children with `expand-x = true`
3. Determine each child’s height:

   * if child `expand-y = true`, child height = full inner height
   * else child height = child minimum height
4. Determine each child’s y position:

   * if child fills full inner height, y = inner top
   * else position according to `align-y`

     * `:start` => top
     * `:center` => vertically centered
     * `:end` => bottom
5. Position children from left to right using spacing.

### Notes

* all spacing is between children only
* no margin collapsing
* layout must be deterministic

---

## 3. VBox

### Purpose

Container that lays out children vertically from top to bottom.

### Properties

* `children`
* `padding-left`
* `padding-right`
* `padding-top`
* `padding-bottom`
* `spacing`
* `align-x`

### Meaning of `align-x`

This is the cross-axis alignment for children inside the `VBox`.

Allowed values:

* `:start`
* `:center`
* `:end`

`VBox` does **not** need `:stretch` because horizontal stretching is controlled by child `expand-x`.

### Minimum size calculation

* `min-width`
  = left padding

  * right padding
  * maximum child minimum width

* `min-height`
  = top padding

  * bottom padding
  * sum of child heights
  * spacing between children

### Layout rules

Given a final rectangle for the `VBox`:

1. Compute inner rectangle by subtracting padding.
2. Determine each child’s height:

   * start with child minimum height
   * compute leftover vertical space
   * distribute leftover equally among children with `expand-y = true`
3. Determine each child’s width:

   * if child `expand-x = true`, child width = full inner width
   * else child width = child minimum width
4. Determine each child’s x position:

   * if child fills full inner width, x = inner left
   * else position according to `align-x`

     * `:start` => left
     * `:center` => horizontally centered
     * `:end` => right
5. Position children from top to bottom using spacing.

---

## 4. ColorRect

### Purpose

Simple visible leaf widget used for testing layout and rendering.

### Properties

* `min-width`
* `min-height`
* `expand-x`
* `expand-y`
* `color`

Color can be represented however is convenient, for example:

* `(r g b a)`
* a struct
* a class

### Minimum size

Directly from its stored values.

### Layout behaviour

None beyond reporting size requirements.
The parent assigns its final rectangle.

### Render behaviour

Draw a filled rectangle using its final rectangle and color.

This should call the backend rectangle draw function.

---

## 5. Filler

### Purpose

Invisible leaf widget used only to absorb extra space.

Typical usage:

* in an `HBox`, place `Button`, `Filler`, `Button`
* filler expands and pushes buttons apart

### Properties

* `min-width`
* `min-height`
* `expand-x`
* `expand-y`

For most common uses:

* min size will be zero
* one or both expand flags will be true

### Minimum size

Directly from stored values.

### Layout behaviour

None beyond reporting size requirements.

### Render behaviour

Does nothing.

### Naming

`Filler` is acceptable for v1.
Alternative names later could be:

* `Spacer`
* `Stretch`
* `Glue`

For now use `Filler`.

---

# Shared Concepts

## Rectangle

All layout and render positions should use a rectangle type with:

* `x`
* `y`
* `width`
* `height`

Use integers.

---

## Size request

Each widget must be able to report a size request containing:

* `min-width`
* `min-height`
* `expand-x`
* `expand-y`

This can be a struct/class/object or multiple return values.

---

# Margins and Padding

## Padding

Padding belongs to containers.
It reduces the inner area available to children.

`HBox` and `VBox` support padding.

`Window` does not need padding in v1.

## Margin

To keep v1 simple, do **not** implement margin yet.

Reason:

* padding and spacing are enough to start
* margin complicates size calculations and tests
* margin can be added later once basic layout works

So for v1:

* **padding: yes**
* **spacing: yes**
* **margin: no**

---

# Alignment Rules

Alignment applies only on the cross axis of a container.

## HBox

Uses `align-y`

Possible values:

* `:start`
* `:center`
* `:end`

## VBox

Uses `align-x`

Possible values:

* `:start`
* `:center`
* `:end`

Alignment only matters when a child does **not** expand on that axis.

If a child expands on the cross axis, it fills that full available cross-axis size.

---

# Expansion Rules

## On the main axis

If one or more children expand on the main axis:

* compute leftover space after giving all children their minimum sizes and accounting for spacing/padding
* distribute leftover equally among expanding children

Example:

* leftover width = 300
* 3 expanding children in an `HBox`
* each gets 100 extra width

This equal split is sufficient for v1.

No weighted expansion in v1.

## On the cross axis

A child either:

* fills full inner cross-axis size if it expands
* or keeps its minimum cross-axis size if it does not

---

# Object Model

Using classes is acceptable and probably a good fit here.

A reasonable model is:

## Base class

`Widget`

Common behaviour:

* ask for size request
* layout into a rectangle
* render
* maybe hold final layout rectangle

## Derived classes

* `Window`
* `HBox`
* `VBox`
* `ColorRect`
* `Filler`

A generic-function style in Common Lisp would fit well.

Possible generic functions:

* `measure`
* `layout`
* `render`

Suggested meanings:

### `measure widget`

Returns the widget’s size request.

### `layout widget rect`

Computes layout for the widget and its descendants, storing final rectangles.

### `render widget`

Renders the widget and its descendants using already-computed rectangles.

This is a good OO design for Lisp.

---

# Internal State

Each widget should probably store its final rectangle after layout.

This makes rendering simple:

* first run layout
* then render using stored rectangles

So each widget instance may hold:

* `layout-rect`

This is acceptable for v1 even though pure functional layout would also work.

Given the GUI nature, some object state is fine here.

---

# Testing Requirements

The layout engine must be testable without rendering.

Tests should verify:

* minimum size calculations
* final child rectangles
* spacing
* padding
* alignment behaviour
* expansion behaviour

Examples of tests to write:

## HBox minimum size

Three children with widths:

* 100
* 50
* 70

Spacing:

* 10 between children

Padding:

* left 5, right 5

Expected min width:

* 5 + 5 + 100 + 50 + 70 + 10 + 10 = 250

Expected min height:

* max child height plus top/bottom padding

## HBox filler distribution

Children:

* left ColorRect width 100, no expand
* filler width 0, expand-x true
* right ColorRect width 100, no expand

Container width:

* 800

Expected:

* filler receives remaining width

## HBox align-y center

Child heights:

* 100
* 150
* 50

HBox inner height:

* 150

Expected:

* 100-high child centered vertically
* 150-high child fills naturally
* 50-high child centered vertically

## VBox similar tests

Equivalent tests for vertical layout.

---

# What v1 Does Not Include

Do not implement yet:

* margin
* preferred size
* weighted expansion
* scrolling
* clipping
* event handling
* mouse hit-testing
* text rendering
* buttons
* labels
* nested windows
* z-order
* hidden/disabled state

Keep v1 small.

---

# Expected Implementation Outline

A good implementation structure might look like this:

## Data types

* `rect`
* `size-request`

## Base widget class

* stores `layout-rect`

## Generic functions

* `measure`
* `layout`
* `render`

## Widget classes

* `window`
* `hbox`
* `vbox`
* `color-rect`
* `filler`

## Layout algorithm

* `window` assigns root rect to child
* `hbox` measures children and computes horizontal allocation
* `vbox` measures children and computes vertical allocation

## Rendering

* containers render children
* `color-rect` draws itself
* `filler` renders nothing

---

# Final Behaviour Summary

## Window

* root
* one child
* gives full window rect to child

## HBox

* lays children left to right
* min width = sum of child widths + spacing + padding
* min height = max child height + padding
* distributes extra width among children with `expand-x`
* vertically aligns children with `align-y`
* child height is either min height or full inner height if `expand-y`

## VBox

* lays children top to bottom
* min height = sum of child heights + spacing + padding
* min width = max child width + padding
* distributes extra height among children with `expand-y`
* horizontally aligns children with `align-x`
* child width is either min width or full inner width if `expand-x`

## ColorRect

* visible leaf
* reports min size and expand flags
* renders a solid rectangle

## Filler

* invisible leaf
* reports min size and expand flags
* usually min size 0 and expands on one axis
* renders nothing
