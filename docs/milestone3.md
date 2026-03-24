# Graphics and Widget Extension Spec

## Goal

Extend the current Lisp GUI system with:

* richer graphics/resource primitives
* image loading and blitting
* font handling and text rendering to surfaces
* two new widgets:

  * `Image`
  * `NinePatch`

This spec assumes the following already exist:

* a C glue layer over SDL
* a Lisp wrapper over that glue layer
* a working layout engine
* the widget system with `Window`, `HBox`, `VBox`, `ColorRect`, and `Filler`

The purpose of this phase is to add image and text resources plus widgets that use them.

Do not redesign the layout system. Extend it in a compatible way.

---

# Design Principles

## 1. Surfaces are mutable pixel buffers

A `Surface` is a Lisp object that wraps a native pixel surface.

Conceptually it maps to an SDL surface.

Surfaces are:

* mutable
* pixel-based
* stored internally in a fixed format
* usable as image resources
* usable as render targets for text rendering and blits

The fixed internal pixel format is:

* **32-bit RGBA**

This is the standard internal format for all loaded and created surfaces.

Do not tie surfaces to the current screen format.

---

## 2. Surface operations use explicit geometry objects

On the Lisp side, define these basic value types:

* `Position`
* `Rect`
* `Color`

These should be used as parameters and return types where appropriate.

### Position

Represents a point:

* `x`
* `y`

### Rect

Represents a rectangle:

* `x`
* `y`
* `width`
* `height`

### Color

Represents a color:

* `r`
* `g`
* `b`
* `a`

All values in these 3 types should be integers.

---

## 3. Blitting is the core image operation

Use the word **blit**, not render, for surface-to-surface copying.

A blit copies pixels from a source surface to a destination surface.

Requirements:

* handle alpha
* clip when source or destination exceeds bounds
* do not scale in this phase unless explicitly required for 9-patch support
* support copying either the whole source or a source sub-rectangle

You can determine the exact SDL details, but the Lisp-side API should clearly express these operations.

---

# Surface Resource Model

## Surface class

Define a Lisp `Surface` class wrapping a native surface handle.

A surface should support:

* creation as a blank surface from width/height
* loading from a file path
* width/height queries
* blitting onto another surface
* possibly freeing the native resource when no longer needed

### Required properties

At minimum, a surface should logically expose:

* width
* height
* native handle internally

The width and height may be cached or queried natively.

---

## Surface creation operations

Support two creation modes:

### 1. Blank surface

Create an empty surface with a given width and height.

The surface should be initialized in the standard 32-bit RGBA format.

### 2. Load from file

Load a surface from a file path.

After loading, convert it to the standard 32-bit RGBA internal format.

The file path is passed from Lisp to the native layer.

The other LLM may choose the SDL image-loading mechanism.

---

## Surface query operations

A surface should expose:

* width
* height
* maybe a convenience function returning a `Rect` at origin `(0, 0)` if useful

At minimum, width and height must be available on the Lisp side.

---

## Surface blit operations

The API must support blitting one surface onto another.

### Basic blit behaviour

* source is copied onto destination
* alpha is respected
* output is clipped to destination bounds
* no implicit scaling for normal image blits in this phase

### Clipping rule

If a blit would exceed destination bounds, only the overlapping portion is copied.

Examples:

* blitting a 10x10 source region onto a 5x5 destination area results in only a 5x5 overlap being copied
* blitting a 5x5 region into a 10x10 destination affects only that 5x5 area

### Geometry support

The API should be able to express:

* blit entire source at a destination position
* blit a source sub-rectangle to a destination position
* for 9-patch support, add an operation that can place a source sub-rectangle into a destination rectangle

Whether that last operation is implemented as a scaled blit or some more specific helper is up to the implementer, but the API must support the needs of 9-patch rendering.

---

# Font Resource Model

## General approach

Use a **hybrid** font model:

* there is a real `Font` object on the Lisp side
* the native side may cache loaded font resources internally
* Lisp can request fonts by specification
* text rendering uses a `Font` object
* convenience helpers may exist later, but the core model is explicit

---

## Font class

Define a Lisp `Font` class wrapping a native font resource.

A font should be identified by at least:

* font family or path/name
* size

The implementation may include style later, but not required now.

The native side may cache fonts by some key such as:

* name + size
  or
* path + size

The exact cache strategy is up to the implementer.

---

## Font operations

Support these logical operations:

### 1. Get or load font

Request a font by name/path and size.

If already loaded, the native layer may reuse the cached instance.

Returns a Lisp `Font` object.

### 2. Measure text

Given a font and a string, return the pixel size required to render it.

This is important for future label/button/text widgets.

The result may be:

* a width/height pair
* a `Rect`
* or a dedicated size object

The exact Lisp representation is flexible, but width and height must be available.

### 3. Render text to surface

Given:

* a `Font`
* a string
* a `Color`

return a new `Surface` containing the rendered text.

Rules:

* anti-aliased text rendering
* text color is supplied at render time
* background is transparent
* output surface uses the standard RGBA format

This text rendering result is a normal surface and can be used by widgets or further blits.

---

# Shared Alignment Model

All widgets now support an internal content alignment value.

Default:

* **top-left**

This is especially relevant for widgets that draw content smaller than their allocated layout rectangle.

For now, define alignment in a simple way sufficient for image rendering and future text/image widgets.

At minimum support:

* top-left
* center
* top-right
* bottom-left
* bottom-right

The exact representation may be:

* one symbol per combined alignment
  or
* separate horizontal and vertical alignment values

The implementation choice is flexible, but it must be consistent.

The default is top-left.

---

# New Widget: Image

## Purpose

An `Image` widget displays a surface.

It is a leaf widget.

It participates in normal layout and renders the image inside its allocated rectangle.

---

## Properties

An `Image` widget should have at least:

* `surface`
* alignment
* any standard widget layout properties already used in the system

If the system later distinguishes widget padding and margin more generally, this widget should fit into that model, but do not redesign margins now unless needed.

---

## Minimum size

The minimum size of the `Image` widget is:

* the width of the surface
* the height of the surface

If there are widget-level padding/insets in your design, they should be included consistently, but do not invent a second layout system here.

---

## Expansion behaviour

In this phase:

* an `Image` widget does **not** scale up when expanded

That means:

* if the layout engine gives it more space, the image remains at native size
* alignment determines where the image is drawn inside the allocated rectangle

---

## Smaller-than-image behaviour

If the allocated rectangle is smaller than the image:

* the image is clipped

Do not scale down.

---

## Render behaviour

The widget draws its surface inside its allocated layout rectangle:

* at native surface size
* positioned according to alignment
* clipped if necessary

This requires the drawing layer to support clipping and/or bounded blitting.

---

# New Widget: NinePatch

## Purpose

A `NinePatch` is a visual container widget that:

* draws a 9-patch image
* contains exactly one optional child
* places that child in the center/content region

It behaves like a skinned panel.

---

## Properties

A `NinePatch` widget should have:

* `surface`
* border sizes:

  * left
  * right
  * top
  * bottom
* optional child
* any normal layout/container properties already appropriate

The `surface` is the source image for the 9-patch.

The border sizes define the 9-patch slices:

* corners are fixed
* edges stretch along one axis
* center stretches in both axes

The content area is the center patch.

Keep it simple:

* the child is laid out directly into the center area
* do not define separate content padding beyond the border sizes in this phase

---

## Minimum size

The minimum size of a `NinePatch` is based on:

* left border
* right border
* top border
* bottom border
* child minimum size if a child exists

So:

* minimum width = left border + right border + child minimum width
* minimum height = top border + bottom border + child minimum height

If no child exists:

* minimum width = left border + right border
* minimum height = top border + bottom border

This widget is a container, so it must integrate with the current layout engine.

---

## Child layout

The child is laid out into the center/content rectangle:

* x = outer x + left border
* y = outer y + top border
* width = outer width - left border - right border
* height = outer height - top border - bottom border

The child receives that center rectangle as its available layout area.

If the center rectangle becomes too small, the normal layout engine rules apply.

---

## Render behaviour

The `NinePatch` draws itself by slicing the source surface into 9 regions:

* top-left corner
* top edge
* top-right corner
* left edge
* center
* right edge
* bottom-left corner
* bottom edge
* bottom-right corner

### Patch rules

* corners are drawn at fixed size
* top and bottom edges stretch horizontally
* left and right edges stretch vertically
* center stretches both horizontally and vertically

After drawing itself, the `NinePatch` renders its child.

This implies the graphics API must support:

* source sub-rectangle selection
* drawing/blitting into a destination rectangle
* scaling for edge and center patches

The other LLM may implement this however it chooses internally, but the public Lisp-side drawing API must make this possible.

---

# Additional Drawing Requirements

To support `Image` and `NinePatch`, the graphics layer should expose enough operations to express:

## 1. Draw surface at position

Copy a whole source surface to a target at a position.

## 2. Draw source sub-rectangle at position

Copy a chosen source rectangle to a target at a destination position.

## 3. Draw source sub-rectangle into destination rectangle

This is needed for 9-patch edges and center.

This operation may scale the source region to fit the destination rectangle.

Even though ordinary image widgets do not scale, 9-patch rendering requires this more advanced operation.

## 4. Clip to destination bounds

Blits must clip correctly to destination bounds.

Whether clipping is implicit in the blit implementation or managed more explicitly is up to the implementer.

---

# Lisp-side Value Types

Define these classes or equivalent structured objects:

## Position

Fields:

* `x`
* `y`

## Rect

Fields:

* `x`
* `y`
* `width`
* `height`

## Color

Fields:

* `r`
* `g`
* `b`
* `a`

These should be used consistently in the public Lisp API for geometry and color arguments.

---

# Public Lisp-side Concepts to Support

The exact function names are up to the implementer, but the API should support the following concepts.

## Surface concepts

* create blank surface from size
* load surface from file path
* query width/height
* blit full surface
* blit source sub-rectangle
* blit source sub-rectangle into destination rectangle

## Font concepts

* get/load font by spec
* measure text
* render text to surface with color and transparent background

## Widget concepts

* `Image` widget using a surface
* `NinePatch` widget using a surface and border sizes
* alignment as a standard widget property
* clipping of oversized content
* no automatic scaling of normal image widgets

---

# Integration with Existing Layout Engine

Do not redesign the layout engine.

The new widgets should fit the current system:

* they report minimum sizes
* they receive final layout rectangles from their parents
* they render within those rectangles

## Image

* minimum size from surface dimensions
* allocated larger area does not cause image scaling
* alignment decides draw position within allocated rect

## NinePatch

* minimum size includes borders and child
* child laid out into center area
* render uses 9-patch slicing rules

---

# Testing Expectations

The implementation should be testable in two layers.

## Layout/widget tests

Without relying on real rendering, verify:

* `Image` minimum size equals surface size
* `Image` alignment affects draw placement correctly
* `NinePatch` minimum size includes borders and child
* `NinePatch` child gets the correct center rectangle

## Graphics/resource tests

Verify:

* blank surface creation works
* file load works
* surfaces use the RGBA format consistently
* blits clip correctly
* source sub-rectangle blits work
* scaled source-subrect-to-destination-rect drawing works for 9-patch
* font lookup/loading works
* text measurement returns sensible sizes
* text rendering returns a surface with transparent background

---

# Out-of-scope for This Phase

Do not add yet:

* image scaling for normal `Image` widgets
* animated images
* font fallback systems
* multiline text layout
* text editing
* buttons/labels as final widgets
* arbitrary transforms
* rotation
* general scene graph changes

Keep this phase focused on:

* surfaces
* fonts
* image drawing
* 9-patch rendering
* widget integration

---

# Summary

Implement the following extension in Lisp plus the existing C/SDL backend:

* `Surface` resource wrapping an RGBA pixel buffer
* `Font` resource with hybrid caching model
* text measurement
* anti-aliased text rendering to transparent RGBA surfaces
* geometry value types: `Position`, `Rect`, `Color`
* richer blit support, including sub-rectangles and destination rectangles
* `Image` widget with alignment and clipping but no scaling
* `NinePatch` container widget with one child and border-defined center content area

The SDL/backend details are up to you, but the Lisp API and object model should match this spec.
