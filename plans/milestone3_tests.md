Below is a set of English test descriptions to turn into concrete unit/integration tests.

These are aimed at the new graphics/resource layer plus the `Image` and `NinePatch` widgets. They assume the layout engine already exists and works.

The tests are grouped by area:

* value objects
* surfaces
* fonts
* image widget
* nine-patch widget
* integration and sanity

The intention is to test logic and API behaviour, not SDL internals.

---

# General guidance

Write unit and integration tests for the new graphics layer and widgets. Prefer small deterministic fixtures. For surfaces, verify creation, loading, size, blitting, clipping, and sub-rectangle copy behaviour. For fonts, verify lookup, caching behaviour, measurement, and rendering to transparent RGBA surfaces. For widgets, verify `Image` minimum size, alignment, clipping, and no-scaling behaviour, plus `NinePatch` minimum size, child layout, and 9-slice rendering correctness. Use pixel-level assertions where appropriate and layout-rectangle assertions elsewhere.

Write tests at two levels:

* **pure Lisp/layout/widget tests** where possible
* **backend/resource tests** for surfaces and fonts

Avoid depending on on-screen rendering unless there is no better option.
Prefer:

* checking sizes
* checking returned objects
* checking rectangles
* checking clipping results
* checking that surfaces changed as expected

Use very small images and very small numbers whenever possible.

Where pixel-level assertions are needed, use tiny artificial test surfaces with simple solid colors and alpha.

---

# 1. Value object tests

## 1. Position stores x and y correctly

Create a `Position` with known values, for example `(10, 20)`.
Assert that:

* `x` is 10
* `y` is 20

This checks the basic geometry value object.

## 2. Rect stores x, y, width, and height correctly

Create a `Rect` with known values, for example `(5, 6, 100, 200)`.
Assert that:

* `x` is 5
* `y` is 6
* `width` is 100
* `height` is 200

## 3. Color stores RGBA correctly

Create a `Color` with known values, for example `(255, 10, 20, 128)`.
Assert that all channels are stored correctly.

## 4. Invalid negative width/height handling is consistent

Try to create a `Rect` with negative width or negative height.
Assert the chosen behaviour is consistent:

* either it signals an error
* or it normalizes values
* or it allows them explicitly

The test should match the intended API, but the result must be deterministic.

---

# 2. Surface creation and metadata tests

## 5. Blank surface can be created with requested size

Create a blank surface with width 32 and height 16.
Assert that:

* the result is a `Surface`
* width is 32
* height is 16

## 6. Loaded surface reports correct size

Load a small known test image from disk, for example 8x6.
Assert that:

* the result is a `Surface`
* width is 8
* height is 6

Use a tiny fixture image whose dimensions are known in advance.

## 7. Loaded surface uses RGBA internal format

Load a known test image.
Assert that the surface is in the standard internal format expected by the Lisp-side API.

The exact check depends on implementation, but this should verify that all loaded surfaces are normalized consistently.

## 8. Creating a blank surface twice gives independent objects

Create two blank surfaces of the same size.
Assert that:

* they are distinct surface objects
* mutating or blitting onto one does not affect the other

## 9. Loading a missing file fails predictably

Attempt to load an image from a clearly invalid path.
Assert that the code behaves consistently:

* signals an error
* or returns a failure object
* or otherwise follows the documented contract

This test should verify failure handling, not just success.

---

# 3. Surface blit tests

Use tiny artificial surfaces for these tests where possible.

A helpful pattern is:

* create a destination surface filled with a known color
* create a source surface filled with another known color
* perform a blit
* inspect selected pixels or output regions

## 10. Full-surface blit copies pixels at destination position

Create:

* a 10x10 destination surface filled with black
* a 4x4 source surface filled with red

Blit the source onto the destination at position `(2, 3)`.

Assert that:

* pixels in the destination rectangle `(2,3)` to `(5,6)` are red
* pixels outside that rectangle remain black

## 11. Blitting clips when source would exceed destination bounds

Create:

* a 5x5 destination surface filled with black
* a 4x4 source surface filled with red

Blit source at position `(3, 3)`.

Only the overlapping bottom-right 2x2 region should be copied.

Assert that:

* destination pixels `(3,3)`, `(4,3)`, `(3,4)`, `(4,4)` are red
* everything else remains black

## 12. Blitting a source sub-rectangle copies only that region

Create a source surface with clearly distinct colored zones.
For example:

* top-left 2x2 red
* top-right 2x2 green
* bottom-left 2x2 blue
* bottom-right 2x2 yellow

Blit only the bottom-right 2x2 source rect into a blank destination at `(0,0)`.

Assert that only yellow pixels were copied.

## 13. Destination position is respected for source sub-rectangle blit

Using the same patterned source, blit a known source sub-rect into a destination position such as `(4,1)`.

Assert that:

* copied pixels appear only at the correct destination offset
* unaffected destination pixels remain unchanged

## 14. Alpha is respected during blit

Create:

* destination surface filled with opaque blue
* source surface filled with semi-transparent red

Blit source onto destination.

Assert that the resulting overlapped pixels are blended as expected, or at least verify that alpha handling is not ignored.

The exact numeric pixel result may depend on implementation details, but the test should verify that alpha affects the output rather than overwriting as fully opaque.

## 15. Blitting onto a larger surface does not modify unrelated regions

Create:

* large destination surface with a known background
* smaller source surface with a different solid color

Blit at a known position.

Assert that only the expected destination region changes.

## 16. Blitting a source onto itself is either supported or fails predictably

Attempt a self-blit case if allowed by the API.
Assert the intended behaviour:

* either it succeeds in a defined way
* or it clearly rejects the operation

This is a good edge-case test.

---

# 4. Scaled blit / source-rect-to-destination-rect tests

These are important for `NinePatch`.

## 17. Source sub-rectangle can be drawn into a larger destination rectangle

Create a small source region with a solid color, for example a 2x2 red block.
Draw it into a 6x6 destination rectangle.

Assert that the resulting 6x6 area is filled appropriately according to the scaling rules.

This checks the existence of scaled copy support.

## 18. Source sub-rectangle can be drawn into a smaller destination rectangle

Create a larger source region and draw it into a smaller destination rectangle.

Assert that:

* the destination rect is affected
* no pixels outside it are touched
* the operation succeeds consistently

This tests downscaling support if implemented for 9-patch operations.

## 19. Scaled destination-rect draw clips correctly at destination bounds

Draw a source sub-rect into a destination rect that extends outside the destination surface bounds.

Assert that:

* output is clipped to destination bounds
* no out-of-bounds corruption occurs

---

# 5. Font loading and caching tests

## 20. A font can be requested by name/path and size

Request a known font with a specific size.
Assert that:

* a `Font` object is returned
* it can be used in later font operations

## 21. Requesting the same font spec twice behaves consistently

Request the same font twice, same name/path and same size.

Assert either:

* the same logical cached resource is reused
* or equivalent `Font` objects are returned

The exact identity semantics depend on the design, but the behaviour should be stable and documented.

## 22. Requesting the same font at different sizes gives distinct usable font objects

Request:

* `Inconsolata` size 12
* `Inconsolata` size 24

Assert that:

* both succeed
* their measured/rendered output differs appropriately

## 23. Requesting a missing font fails predictably

Try to load a font that does not exist.
Assert consistent failure behaviour.

This should test the API contract for missing resources.

---

# 6. Text measurement tests

## 24. Measuring a non-empty string returns positive width and height

Measure `"Hello"` with a known valid font.
Assert that:

* width > 0
* height > 0

## 25. Measuring the empty string behaves consistently

Measure `""`.
Assert the intended behaviour:

* width may be 0
* height may be 0 or the font line height depending on design

The test should pin down whatever behaviour the implementation chooses.

## 26. Larger font size produces larger text measurements

Measure the same string with:

* size 12 font
* size 24 font

Assert that the 24-point measurement is larger in width and/or height.

## 27. Longer strings usually measure wider than shorter strings

Measure `"Hi"` and `"Hello world"` using the same font.

Assert that the longer string has greater width.

This is a sanity test, not a typography proof.

---

# 7. Text rendering to surface tests

## 28. Rendering text returns a surface

Render `"Hello"` using a valid font and color.
Assert that:

* the result is a `Surface`
* width > 0
* height > 0

## 29. Rendered text surface size matches measured text size

Measure a string, then render the same string with the same font.

Assert that the rendered surface dimensions match the measured dimensions, or at least are consistent with the documented contract.

## 30. Text color affects rendered output

Render the same text twice:

* once in white
* once in red

Assert that the resulting surfaces are not identical and that the visible text color changes accordingly.

## 31. Rendered text background is transparent

Render text to a surface and inspect pixels in areas expected to be background.

Assert that the background alpha is transparent rather than opaque black or another solid color.

## 32. Rendering empty string behaves consistently

Render `""`.
Assert the chosen behaviour:

* maybe returns an empty/zero-size surface
* maybe returns a minimal transparent surface
* maybe signals an error

The important thing is consistency.

---

# 8. Image widget measurement tests

## 33. Image widget minimum size matches surface size

Create a surface of known size, for example 20x10.
Wrap it in an `Image` widget.

Assert that the widget’s minimum size is:

* width 20
* height 10

## 34. Image widget with larger allocated rect does not scale image

Create an `Image` widget using a 20x10 surface.
Lay it out into a larger rectangle, for example 100x100.

Assert that:

* the widget’s allocated rect is 100x100 if layout gives it that
* but the image draw region remains 20x10
* alignment determines its position within the allocated rect

This may need either draw-command inspection or a test double backend.

## 35. Image widget clips when allocated rect is smaller than the image

Use an image of 20x20 and allocate a rect of 5x5.

Assert that rendering only affects the 5x5 visible area.

This checks clipping behaviour for oversized content.

---

# 9. Image widget alignment tests

Use a small known surface and a larger allocated rectangle.

## 36. Default alignment is top-left

Create an image widget with no explicit alignment and allocate it into a larger rect.

Assert that the image is drawn at the top-left of the allocated area.

## 37. Center alignment centers the image within the allocated rectangle

Allocate a larger rect and set alignment to center.

Assert that the image draw position is centered correctly.

## 38. Top-right alignment positions image at top-right

Same pattern for top-right.

## 39. Bottom-left alignment positions image at bottom-left

Same pattern for bottom-left.

## 40. Bottom-right alignment positions image at bottom-right

Same pattern for bottom-right.

These tests should inspect the actual destination rectangle used for drawing, or the changed pixel region if using a test surface.

---

# 10. NinePatch measurement tests

## 41. NinePatch with no child has minimum size equal to border sums

Create a `NinePatch` with:

* left 3
* right 4
* top 5
* bottom 6
* no child

Assert that its minimum size is:

* width = 7
* height = 11

## 42. NinePatch with child includes child minimum size

Create a child widget with known minimum size, for example 100x50.
Wrap it in a `NinePatch` with borders:

* left 3
* right 4
* top 5
* bottom 6

Assert that minimum size is:

* width = 3 + 4 + 100 = 107
* height = 5 + 6 + 50 = 61

## 43. NinePatch minimum size updates when child changes

If the object model allows changing the child, replace the child with a larger one.

Assert that the `NinePatch` minimum size changes accordingly.

---

# 11. NinePatch child layout tests

## 44. NinePatch lays out child into center/content area

Create a `NinePatch` with borders:

* left 10
* right 20
* top 5
* bottom 15

Lay it out into an outer rect:

* x 100
* y 50
* width 200
* height 100

Assert that the child receives:

* x = 110
* y = 55
* width = 170
* height = 80

## 45. NinePatch with no child does not fail during layout

Lay out a `NinePatch` with no child.
Assert that layout succeeds and no child layout is attempted.

## 46. Nested child layout still works inside NinePatch

Use a child that is itself a container, such as a `VBox`.
Lay out the `NinePatch`.
Assert that:

* the `VBox` receives the center rect
* then lays out its own children relative to that rect correctly

This checks recursive integration.

---

# 12. NinePatch rendering tests

Use a tiny specially-crafted source image whose 9 regions are easy to distinguish by color.

For example, create a 9-patch source where:

* top-left corner is red
* top edge is green
* top-right is blue
* left edge is yellow
* center is magenta
* right edge is cyan
* bottom-left is orange
* bottom edge is purple
* bottom-right is white

## 47. NinePatch corners remain fixed size

Render the `NinePatch` larger than its source size.

Assert that:

* each corner appears at the correct output corner
* each corner keeps its original dimensions
* corners are not stretched

## 48. NinePatch top and bottom edges stretch horizontally

Using the same test image, assert that:

* top edge fills the space between top corners
* bottom edge fills the space between bottom corners
* their thickness remains fixed vertically

## 49. NinePatch left and right edges stretch vertically

Assert that:

* left edge fills space between top-left and bottom-left corners
* right edge fills space between top-right and bottom-right corners
* their widths remain fixed horizontally

## 50. NinePatch center patch stretches to fill remaining middle area

Assert that the center area fills the full content/background area between borders.

## 51. NinePatch rendering clips correctly when output rect is partially out of bounds

Draw a `NinePatch` so part of its destination rect lies outside the destination surface.

Assert that:

* output is clipped safely
* visible portions are still correct

---

# 13. NinePatch + child rendering order tests

## 52. NinePatch renders background before child

Use a child `ColorRect` inside a `NinePatch`.
Render to a destination.

Assert that:

* the nine-patch frame/background appears
* the child appears on top of the center area

This can be checked with carefully chosen colors and pixel inspection.

## 53. Child rendering is confined to content area assigned by NinePatch

Use a child larger than the content area or one that would visually exceed it if unclipped.

Assert that child rendering respects the child’s allocated rectangle/content placement policy.

Depending on current clipping support, this may verify either clipping or at least correct placement.

---

# 14. Integration tests

## 54. Image widget inside NinePatch reports correct overall minimum size

Put an `Image` widget with known surface size inside a `NinePatch` with known borders.

Assert that:

* image minimum size is correct
* nine-patch minimum size includes image + borders

## 55. Text surface can be wrapped in an Image widget

Render text to a surface, then create an `Image` widget from that surface.

Assert that:

* image minimum size matches rendered text surface dimensions
* widget can be laid out normally

This is a very important bridge test between fonts and widgets.

## 56. NinePatch containing text-image widget lays out correctly

Render text to a surface, wrap it in an `Image`, then place that inside a `NinePatch`.

Assert that:

* minimum size is correct
* child is placed in the center/content area correctly

## 57. Multiple images in HBox still obey prior layout rules

Create an `HBox` containing:

* image widget
* filler
* image widget

Assert that:

* image minimum sizes come from surfaces
* filler absorbs extra width
* images keep native size and align within allocated regions

This checks compatibility with the existing layout engine.

---

# 15. Resource lifecycle / robustness tests

## 58. Repeated creation and disposal of surfaces does not fail

Create and destroy many small blank surfaces in a loop.

Assert that the operations succeed consistently.

## 59. Repeated font lookup/render operations do not fail

Repeatedly request the same font and render small strings.

Assert stable behaviour over multiple runs.

## 60. Loading, measuring, rendering, and widget wrapping work together in one flow

Run a complete flow:

* load font
* measure text
* render text to surface
* create image widget from surface
* place image widget inside nine-patch
* lay out full tree
* render to destination surface

Assert that each step succeeds and the final output has the expected size/placement properties.

This is a high-value end-to-end test.

---

# 16. Determinism tests

## 61. Repeated text measurement returns identical results

Measure the same string with the same font twice.

Assert equal width and height.

## 62. Repeated text rendering of the same string and color is consistent

Render the same text twice using the same font and color.

Assert that:

* dimensions are identical
* pixel content is identical, or at least equivalent if the backend has deterministic output

## 63. Repeated NinePatch layout produces identical child rectangles

Run layout on the same widget tree twice.

Assert identical final rectangles.

## 64. Repeated Image widget rendering with same inputs is identical

Render the same image widget into the same target twice starting from a blank destination.

Assert identical pixel results.


