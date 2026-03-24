Below is a set of test ideas written in plain English.

I have grouped them by topic. The intention is that these tests check only the layout logic, not real rendering.

# General assumptions

All tests should:

* create a widget tree
* run the layout pass
* inspect the final rectangles assigned to each widget
* also inspect measured minimum sizes where relevant

Use simple numbers so expected results are easy to verify by hand.

Unless stated otherwise:

* all coordinates and sizes are integers
* `Window` starts at `(0, 0)`
* `ColorRect` renders nothing important for these tests; we only care about its final layout rectangle
* `Filler` is invisible, but must still receive a correct layout rectangle

---

# 1. Window passes full size to its child

Create a `Window` of width 800 and height 600, containing one `ColorRect` with minimum size 100 by 50.

The child should receive a final rectangle at `(0, 0)` with width 100 and height 50 if it does not expand.

This test checks that:

* the window acts as the root
* the child is laid out relative to the window origin
* the child is not automatically stretched when expand is false

---

# 2. Window with expanding child fills available space

Create a `Window` of width 800 and height 600, containing one `ColorRect` with minimum size 100 by 50, and with both `expand-x` and `expand-y` set to true.

The child should receive a final rectangle at `(0, 0)` with width 800 and height 600.

This test checks that:

* the root container passes full available space
* expanding children grow to fill on axes where expansion is enabled

---

# 3. HBox minimum width is sum of child widths plus spacing and padding

Create an `HBox` with:

* left padding 10
* right padding 20
* top padding 5
* bottom padding 5
* spacing 7

Add three children with minimum sizes:

* child A: 50 by 30
* child B: 80 by 20
* child C: 40 by 60

The `HBox` minimum width should be:

* 10 + 20 + 50 + 80 + 40 + 7 + 7 = 214

The `HBox` minimum height should be:

* 5 + 5 + max(30, 20, 60) = 70

This test checks that:

* widths are added horizontally
* spacing is added only between children
* height is based on the tallest child
* padding is included properly

---

# 4. VBox minimum height is sum of child heights plus spacing and padding

Create a `VBox` with:

* left padding 3
* right padding 4
* top padding 10
* bottom padding 20
* spacing 5

Add three children with minimum sizes:

* child A: 50 by 30
* child B: 80 by 20
* child C: 40 by 60

The `VBox` minimum width should be:

* 3 + 4 + max(50, 80, 40) = 87

The `VBox` minimum height should be:

* 10 + 20 + 30 + 20 + 60 + 5 + 5 = 150

This test checks the vertical counterpart of the previous test.

---

# 5. HBox positions non-expanding children left to right

Create a `Window` of width 300 and height 100.
Inside it, place an `HBox` with:

* no padding
* spacing 10
* `align-y = :start`

Add three children, all non-expanding:

* child A: 50 by 20
* child B: 60 by 30
* child C: 40 by 10

Expected x positions:

* A at x = 0
* B at x = 60
* C at x = 130

Expected widths:

* A = 50
* B = 60
* C = 40

This test checks:

* left-to-right placement
* correct use of spacing
* no accidental expansion

---

# 6. VBox positions non-expanding children top to bottom

Create a `Window` of width 200 and height 300.
Inside it, place a `VBox` with:

* no padding
* spacing 8
* `align-x = :start`

Add three children, all non-expanding:

* child A: 50 by 20
* child B: 60 by 30
* child C: 40 by 10

Expected y positions:

* A at y = 0
* B at y = 28
* C at y = 66

This checks top-to-bottom placement and vertical spacing.

---

# 7. HBox distributes leftover width equally among expanding children

Create a `Window` of width 400 and height 100.
Inside it, place an `HBox` with:

* no padding
* spacing 10

Children:

* child A: min size 50 by 20, `expand-x = false`
* child B: min size 30 by 20, `expand-x = true`
* child C: min size 20 by 20, `expand-x = true`

Total minimum width plus spacing:

* 50 + 30 + 20 + 10 + 10 = 120

Leftover width:

* 400 - 120 = 280

There are two expanding children, so each gets 140 extra width.

Expected final widths:

* A = 50
* B = 170
* C = 160

This checks:

* leftover width calculation
* equal distribution among expanders
* non-expanding child keeps its minimum width

---

# 8. VBox distributes leftover height equally among expanding children

Create a `Window` of width 100 and height 300.
Inside it, place a `VBox` with:

* no padding
* spacing 10

Children:

* child A: min size 20 by 50, `expand-y = false`
* child B: min size 20 by 30, `expand-y = true`
* child C: min size 20 by 20, `expand-y = true`

Total minimum height plus spacing:

* 50 + 30 + 20 + 10 + 10 = 120

Leftover height:

* 300 - 120 = 180

Two expanding children, so each gets 90 extra height.

Expected final heights:

* A = 50
* B = 120
* C = 110

This checks the vertical equivalent.

---

# 9. Filler expands and pushes siblings apart in an HBox

Create a `Window` of width 500 and height 100.
Inside it, place an `HBox` with:

* no padding
* no spacing

Children:

* left `ColorRect`: min 100 by 40, non-expanding
* middle `Filler`: min 0 by 0, `expand-x = true`
* right `ColorRect`: min 100 by 40, non-expanding

Expected final widths:

* left = 100
* filler = 300
* right = 100

Expected x positions:

* left at 0
* filler at 100
* right at 400

This checks the main practical use of `Filler`.

---

# 10. Filler with spacing still pushes siblings apart correctly

Same as previous test, but set `HBox` spacing to 10.

Total fixed width:

* 100 + 100 + 10 + 10 = 220

Leftover width:

* 500 - 220 = 280

Expected:

* left width = 100
* filler width = 280
* right width = 100

Expected x positions:

* left at 0
* filler at 110
* right at 400

This checks interaction of filler and spacing.

---

# 11. HBox align-y start places smaller children at the top

Create a `Window` of width 300 and height 150.
Inside it, place an `HBox` with no padding, no spacing, `align-y = :start`.

Children:

* A: 50 by 100, non-expanding
* B: 50 by 150, non-expanding
* C: 50 by 50, non-expanding

Expected:

* A y = 0, height = 100
* B y = 0, height = 150
* C y = 0, height = 50

This checks top alignment in the cross axis.

---

# 12. HBox align-y center centers smaller children vertically

Use the same setup as the previous test, but `align-y = :center`.

Expected:

* A y = 25, height = 100
* B y = 0, height = 150
* C y = 50, height = 50

This checks center alignment in the cross axis.

---

# 13. HBox align-y end bottom-aligns smaller children

Same setup again, but `align-y = :end`.

Expected:

* A y = 50, height = 100
* B y = 0, height = 150
* C y = 100, height = 50

This checks end alignment in the cross axis.

---

# 14. VBox align-x start places smaller children on the left

Create a `Window` of width 200 and height 300.
Inside it, place a `VBox` with no padding, no spacing, `align-x = :start`.

Children:

* A: 100 by 50, non-expanding
* B: 200 by 50, non-expanding
* C: 50 by 50, non-expanding

Expected:

* A x = 0, width = 100
* B x = 0, width = 200
* C x = 0, width = 50

This checks left alignment in the cross axis.

---

# 15. VBox align-x center centers smaller children horizontally

Same setup, but `align-x = :center`.

Expected:

* A x = 50, width = 100
* B x = 0, width = 200
* C x = 75, width = 50

This checks center alignment horizontally.

---

# 16. VBox align-x end right-aligns smaller children

Same setup, but `align-x = :end`.

Expected:

* A x = 100, width = 100
* B x = 0, width = 200
* C x = 150, width = 50

This checks end alignment horizontally.

---

# 17. Child expanding on cross axis fills full cross-axis size

Create a `Window` of width 300 and height 150.
Inside it, place an `HBox` with `align-y = :center`.

Children:

* A: 50 by 100, `expand-y = false`
* B: 50 by 20, `expand-y = true`

Expected:

* A gets height 100 and is centered vertically, so y = 25
* B gets height 150 and y = 0

This checks that expansion on the cross axis overrides alignment and fills the available size.

---

# 18. Child expanding on main axis and cross axis fills both where appropriate

Create a `Window` of width 400 and height 200.
Inside it, place an `HBox`.

Children:

* A: 100 by 50, `expand-x = false`, `expand-y = false`
* B: 50 by 20, `expand-x = true`, `expand-y = true`

No spacing or padding.

Expected:

* A width = 100, height = 50
* B gets all remaining width and full height

This checks combined expansion behaviour.

---

# 19. Padding reduces inner area correctly

Create a `Window` of width 300 and height 200.
Inside it, place an `HBox` with:

* left padding 10
* right padding 20
* top padding 5
* bottom padding 15
* no spacing
* `align-y = :start`

One child:

* A: 50 by 30, non-expanding

Expected:

* child x = 10
* child y = 5
* child width = 50
* child height = 30

The inner area height is:

* 200 - 5 - 15 = 180

But because the child is non-expanding, its height remains 30.

This checks that padding affects child placement and available size.

---

# 20. Nested containers compute positions correctly

Create a `Window` of width 500 and height 300.

Its child is a `VBox` with:

* padding 10 on all sides
* spacing 20
* `align-x = :start`

The `VBox` has two children:

* top child: `ColorRect`, min 100 by 50
* bottom child: `HBox`, min determined by its children

The `HBox` has:

* spacing 10
* no padding
* `align-y = :center`

The `HBox` children are:

* left rect: 50 by 100
* right rect: 50 by 50

This test should verify:

* the `VBox` positions the top child first
* the `HBox` is placed below with the correct y offset
* the `HBox` then positions its own children correctly relative to its own rectangle
* nested coordinates are all absolute and correct

This checks recursive layout.

---

# 21. Empty HBox minimum size is just its padding

Create an `HBox` with:

* left padding 10
* right padding 20
* top padding 5
* bottom padding 15
* no children

Expected minimum width:

* 30

Expected minimum height:

* 20

This checks empty-container behaviour.

---

# 22. Empty VBox minimum size is just its padding

Same idea for `VBox`.

This checks the vertical container counterpart.

---

# 23. Single child in HBox behaves correctly with no spacing

Create a `Window` of width 300 and height 100.
Inside it, place an `HBox` with no padding, no spacing.

One child:

* A: 70 by 20, non-expanding

Expected:

* A at x = 0, y according to alignment
* width = 70
* height = 20

This checks that the container behaves sensibly in the one-child case.

---

# 24. Single child in VBox behaves correctly with no spacing

Equivalent vertical test.

---

# 25. No expanding children leaves unused extra space unassigned

Create a `Window` of width 400 and height 100.
Inside it, place an `HBox` with no padding and no spacing.

Children:

* A: 50 by 20, non-expanding
* B: 50 by 20, non-expanding

Expected:

* A width = 50
* B width = 50
* total used width = 100
* extra 300 pixels are not distributed to either child

This checks that non-expanding widgets do not accidentally stretch.

---

# 26. Multiple fillers split extra space equally

Create a `Window` of width 500 and height 100.
Inside it, place an `HBox` with no spacing.

Children:

* fixed left rect: 100 by 20
* filler A: 0 by 0, `expand-x = true`
* filler B: 0 by 0, `expand-x = true`
* fixed right rect: 100 by 20

Total fixed width = 200
Leftover = 300

Expected:

* filler A width = 150
* filler B width = 150

This checks equal expansion distribution among multiple fillers.

---

# 27. Cross-axis expansion does not affect main-axis minimum size calculation

Create an `HBox` with three children:

* A: 50 by 20, `expand-y = true`
* B: 80 by 30, `expand-y = false`
* C: 40 by 10, `expand-y = true`

Expected minimum width:

* 50 + 80 + 40 plus spacing/padding

Expected minimum height:

* based on tallest minimum height, which is 30

This checks that cross-axis expansion does not distort measurement on the main axis.

---

# 28. Main-axis expansion does not affect cross-axis minimum size calculation

Equivalent `VBox` test.

---

# 29. Final rectangles should never be negative in normal valid layouts

Create a small but valid layout where the window is exactly equal to the root minimum size.

Verify that all children end up with:

* non-negative x and y
* non-negative width and height

This checks basic sanity.

---

# 30. Layout is deterministic

Create one moderately nested widget tree.
Run layout twice without changing anything.

All measured minimum sizes and final rectangles should be identical between runs.

This checks that layout has no hidden instability.
