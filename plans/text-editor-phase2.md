Below is a focused implementation spec for Stage 2 of the text editor widget.

It assumes Stage 1 already exists and works:

* `TextEditor` widget exists
* it can receive focus when clicked
* it receives text input when focused
* typed text appears
* caret is visible and blinks
* there is a simple internal text model

This phase adds the first real editing and navigation behaviour.

---

# Minerva Text Editor Widget — Stage 2 Spec

## Goal

Extend the `TextEditor` widget so it behaves like a basic one-buffer text editor rather than just a text entry field.

At the end of Stage 2, the editor should support:

* left/right arrow movement
* up/down arrow movement
* Backspace
* Delete
* Enter inserting a new line
* Home moving to start of line
* End moving to end of line

This stage should still stay simple.
It should aim for something in the rough usability range of a tiny editor, not a full IDE.

This stage does **not** need to support yet:

* scrolling
* scrollbars
* mouse-based caret placement by x/y
* selection
* clipboard
* syntax highlighting
* undo/redo
* word movement
* page up/page down
* multiline wrapping
* tabs with special width rules
* proportional-font editing complexity

---

# Part 1: Text Model Upgrade

## Goal

Stage 1 could use a single-line buffer.
Stage 2 now needs multiple lines.

## Required representation

Upgrade the text model so the editor stores text as a sequence of lines.

A simple representation is acceptable, for example:

* a vector/list/array of strings
* or a vector/list/array of character arrays

Do not optimize heavily yet.

The representation only needs to support:

* inserting characters into a line
* splitting a line
* joining lines
* deleting characters before/after the caret
* moving between lines

---

## Required editor state

The `TextEditor` widget should now store at least:

* lines of text
* caret line index
* caret column index
* focused state or integration with global focus
* blink state / blink timing as before
* preferred column for vertical movement

### Meaning

#### lines of text

An ordered sequence of lines.

Examples:

* `["hello"]`
* `["one" "two" "three"]`
* `["" "abc" ""]`

There should always be at least one line.

#### caret line index

Zero-based line number where the caret currently is.

#### caret column index

Zero-based column within the current line.

Valid range:

* `0` to `length(current-line)`

#### preferred column

Used when moving vertically with up/down.

Example:

* cursor is at column 10 on a long line
* move down to a shorter line, caret lands at line end
* move down again to a longer line, it should try to return to column 10

This is standard editor behaviour.

If implementing preferred column now feels too much, it may be approximated, but it is recommended even in Stage 2.

---

# Part 2: Rendering Upgrade

## Goal

The editor must now render multiple lines of text.

## Required behaviour

The editor should render all current lines in order from top to bottom.

For Stage 2:

* assume no scrolling yet
* render from the top of the editor rect
* if there are more lines than fit vertically, clipping is acceptable

Each line should be rendered on its own line using the existing font/text rendering support.

Use a simple fixed line height based on the font.

---

## Caret rendering

The caret must now be rendered based on:

* caret line
* caret column

Its on-screen position should be computed from:

* line number
* line height
* width of text before the caret on that line

For Stage 2:

* horizontal clipping is acceptable if line is wider than widget
* vertical clipping is acceptable if too many lines exist

No scrolling yet.

---

# Part 3: Key Event Handling

## Goal

The focused editor should now respond to key-down events for navigation and editing.

## Required keys for this phase

Support these keys:

* Left
* Right
* Up
* Down
* Backspace
* Delete
* Enter
* Home
* End

These should come through the Minerva event system as `:key-down` events with normalized key names.

Example:

```lisp
(:key-down :key :left)
(:key-down :key :backspace)
(:key-down :key :enter)
```

---

# Part 4: Horizontal Movement

## Left Arrow

When the focused editor receives:

```lisp
(:key-down :key :left)
```

the caret should move one position left.

### Rules

* if `caret-column > 0`, decrement column
* if `caret-column = 0` and `caret-line > 0`, move to end of previous line
* if already at start of first line, do nothing

After movement:

* reset preferred column appropriately
* make caret visible
* reset blink timing
* request redraw

---

## Right Arrow

When the focused editor receives:

```lisp
(:key-down :key :right)
```

the caret should move one position right.

### Rules

* if `caret-column < length(current-line)`, increment column
* if `caret-column = length(current-line)` and there is a next line, move to start of next line
* if already at end of last line, do nothing

After movement:

* reset preferred column appropriately
* make caret visible
* reset blink timing
* request redraw

---

# Part 5: Vertical Movement

## Goal

Up/down should move between lines sensibly.

## Up Arrow

When the focused editor receives:

```lisp
(:key-down :key :up)
```

### Rules

* if already on first line, do nothing
* otherwise move to previous line
* caret column becomes:

  * preferred column if available, clamped to previous line length
  * or current column clamped, if preferred column handling is simple

After movement:

* keep/update preferred column
* make caret visible
* reset blink timing
* request redraw

---

## Down Arrow

When the focused editor receives:

```lisp
(:key-down :key :down)
```

### Rules

* if already on last line, do nothing
* otherwise move to next line
* caret column becomes:

  * preferred column if available, clamped to next line length
  * or current column clamped, if preferred column handling is simple

After movement:

* keep/update preferred column
* make caret visible
* reset blink timing
* request redraw

---

# Part 6: Enter / Newline

## Goal

Pressing Enter should split the current line.

When the focused editor receives:

```lisp
(:key-down :key :enter)
```

it should insert a newline at the caret position.

## Rules

Suppose current line is:

* `"hello|world"` where `|` is caret

After Enter:

* current line becomes `"hello"`
* a new next line becomes `"world"`
* caret moves to:

  * next line
  * column 0

Examples:

### Example 1

Before:

* lines = `["abc"]`
* caret at line 0, column 1

Text visual:

* `a|bc`

After Enter:

* lines = `["a" "bc"]`
* caret = line 1, column 0

### Example 2

Before:

* line text `"abc"`
* caret at end

After Enter:

* lines become `["abc" ""]`
* caret on new empty line

After insertion:

* make caret visible
* reset blink timing
* request redraw

---

# Part 7: Backspace

## Goal

Backspace deletes the character before the caret, or joins with previous line when at column 0.

When the focused editor receives:

```lisp
(:key-down :key :backspace)
```

apply these rules.

## Rules

### Case A: caret-column > 0

Delete the character immediately before the caret.

Example:

* `"ab|c"` → `"a|c"`

### Case B: caret-column = 0 and not first line

Join current line onto the end of previous line.

Example:
Before:

* lines = `["abc" "def"]`
* caret at line 1, column 0

After:

* lines = `["abcdef"]`
* caret at line 0, column 3

### Case C: caret-column = 0 on first line

Do nothing.

After edit:

* make caret visible
* reset blink timing
* request redraw

---

# Part 8: Delete

## Goal

Delete removes the character after the caret, or joins with next line when at end of line.

When the focused editor receives:

```lisp
(:key-down :key :delete)
```

apply these rules.

## Rules

### Case A: caret-column < length(current-line)

Delete the character at the caret position.

Example:

* `"ab|c"` → `"ab|"`

### Case B: caret-column = length(current-line)` and not last line

Join next line onto current line.

Example:
Before:

* lines = `["abc" "def"]`
* caret at line 0, column 3

After:

* lines = `["abcdef"]`
* caret remains line 0, column 3

### Case C: at end of last line

Do nothing.

After edit:

* make caret visible
* reset blink timing
* request redraw

---

# Part 9: Home and End

## Home

When the focused editor receives:

```lisp
(:key-down :key :home)
```

move caret to:

* current line
* column 0

After movement:

* update preferred column
* make caret visible
* reset blink timing
* request redraw

---

## End

When the focused editor receives:

```lisp
(:key-down :key :end)
```

move caret to:

* current line
* column = length(current-line)

After movement:

* update preferred column
* make caret visible
* reset blink timing
* request redraw

---

# Part 10: Preferred Column Behaviour

## Goal

Vertical movement should feel natural.

## Required behaviour

When moving left/right/home/end or inserting/deleting text in a way that explicitly changes horizontal position:

* update preferred column to the new caret column

When moving up/down:

* use preferred column if available
* clamp to target line length

This is recommended because otherwise moving vertically across uneven line lengths feels wrong.

If the implementation prefers to defer preferred-column behaviour, it may use current column clamped instead, but preferred column is strongly encouraged in Stage 2.

---

# Part 11: Text Input Still Works

## Goal

Stage 1 text input must continue to work.

When the focused editor receives:

```lisp
(:text-input :text "abc")
```

it should still insert text at the current caret position.

Now that the editor is multiline:

* insert text into the current line at caret
* move caret forward by inserted length

For Stage 2, it is acceptable to assume `:text-input` does not contain embedded newline characters.
If it does, either:

* reject/split simply
* or leave it unsupported for now

Document whichever choice is used.

---

# Part 12: Redraw / Blink Rules

## Goal

Editing and navigation should keep the caret behaviour sensible.

Whenever:

* caret moves
* text changes
* editor gains focus

the widget should:

* make caret visible
* reset blink timer/state
* request redraw

The existing blink logic from Stage 1 should continue to work.

---

# Part 13: Minimum Size

## Goal

The editor should still report a sensible minimum size.

For Stage 2, it is acceptable for minimum size to remain simple, for example:

* enough for several lines of text
* fixed width
* font-height-based minimum height

Do not complicate minimum size with content-dependent growth in this stage.

---

# Part 14: Manual Test Scenarios

The following manual tests should work at the end of Stage 2.

## 1. Basic typing

* click editor
* type `hello`
* text appears
* caret moves to end

## 2. Enter splits line

* type `hello`
* press Left twice
* press Enter
* text becomes:

  * `hel`
  * `lo`
* caret goes to start of second line

## 3. Backspace within line

* type `abc`
* press Backspace
* text becomes `ab`

## 4. Backspace at line start joins lines

* create two lines
* move caret to start of second line
* press Backspace
* lines join correctly

## 5. Delete within line

* type `abc`
* move left once
* press Delete
* correct character is removed

## 6. Delete at line end joins lines

* create two lines
* move caret to end of first line
* press Delete
* lines join correctly

## 7. Arrow movement

* move left/right within line
* move across line boundaries
* move up/down between lines

## 8. Home/End

* move within line
* press Home
* caret goes to start
* press End
* caret goes to end

---

# Part 15: Automated Test Requirements

This phase should be testable without manual rendering-only checks.

## State tests

### 1. Enter splits line correctly

Create an editor with text and caret in middle of line.
Send Enter.
Assert:

* two lines result
* caret moves to next line start

### 2. Backspace deletes previous character

Assert correct resulting text and caret.

### 3. Backspace at column 0 joins with previous line

Assert:

* line count decreases
* text joins correctly
* caret position is correct

### 4. Delete deletes next character

Assert correct resulting text and caret.

### 5. Delete at line end joins with next line

Assert:

* line count decreases
* text joins correctly
* caret stays at correct position

### 6. Left arrow movement

Assert:

* moves within line
* moves to previous line end at column 0
* does nothing at start of document

### 7. Right arrow movement

Assert:

* moves within line
* moves to next line start at line end
* does nothing at end of document

### 8. Up/down movement

Assert:

* moves between lines
* clamps correctly to shorter line
* preferably preserves preferred column

### 9. Home/End

Assert correct caret movement within current line.

### 10. Text input still inserts at caret

Given multiline content, insert text in middle of a line.
Assert text and caret update correctly.

### 11. Caret bounds remain valid

After all operations, assert:

* line index is valid
* column index is valid for current line

### 12. Redraw requested after edit/move

Assert that editing or cursor movement requests redraw.

---

# Part 16: Example State Transformations

## Example 1: Enter in middle of line

Before:

* lines = `["hello world"]`
* caret = line 0, column 5

After Enter:

* lines = `["hello" " world"]`
* caret = line 1, column 0

---

## Example 2: Backspace at start of second line

Before:

* lines = `["abc" "def"]`
* caret = line 1, column 0

After Backspace:

* lines = `["abcdef"]`
* caret = line 0, column 3

---

## Example 3: Right arrow at end of line

Before:

* lines = `["abc" "def"]`
* caret = line 0, column 3

After Right:

* caret = line 1, column 0

---

## Example 4: Delete at end of line

Before:

* lines = `["abc" "def"]`
* caret = line 0, column 3

After Delete:

* lines = `["abcdef"]`
* caret = line 0, column 3

---

# Part 17: Out of Scope for Stage 2

Do **not** add yet:

* scrolling
* scrollbars
* mouse-based caret placement by click position
* selections
* copy/paste
* undo/redo
* syntax highlighting
* wrapped lines
* tabs with visual tab stops
* page up/down
* word movement
* multiline text input payload handling beyond basic assumptions

Keep this phase focused on:

* caret navigation
* line splitting/joining
* deletion
* multiline rendering

---

# Part 18: Summary

Implement Stage 2 of `TextEditor` so that it supports:

* multiline text storage
* caret line/column movement
* left/right/up/down
* Enter
* Backspace
* Delete
* Home
* End
* multiline rendering
* continued caret blinking and redraw behaviour

At the end of this phase, the editor should feel like a tiny but real text editor rather than only a text-entry field.
