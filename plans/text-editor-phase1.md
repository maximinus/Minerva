Below is a focused implementation spec for Stage 1 of the text editor widget.

It assumes the following already exist:

* layout engine
* widget tree and basic widgets
* SDL/backend events converted into Minerva events
* event routing to widgets
* overlays/menu system
* rendering primitives
* text rendering to surfaces or an equivalent way to draw text

This phase adds only the first minimal editor behaviour.

---

# Minerva Text Editor Widget — Stage 1 Spec

## Goal

Implement the first working version of a `TextEditor` widget.

This stage is intentionally small.

At the end of Stage 1, the editor should support:

* receiving focus when clicked
* receiving keyboard input when focused
* inserting typed text into its buffer
* displaying that text
* displaying a blinking caret at the insertion point

This stage does **not** need to support yet:

* arrow-key cursor movement
* backspace/delete
* Enter/newlines
* selection
* scrolling
* scrollbars
* mouse drag
* clipboard
* syntax highlighting
* multiple cursors
* advanced text storage

The text storage may be very simple for now.

---

# Part 1: New Widget

## Required widget

Add a `TextEditor` widget.

It should behave like a normal widget in the current system:

* it has a layout rectangle
* it can render itself
* it can receive Minerva events
* it can request redraw when its state changes

---

# Part 2: Text Model for Stage 1

## Goal

Keep the internal text storage very simple.

For this phase, text may be stored as either:

### Option A

A single mutable string-like structure

or

### Option B

A simple array/vector of characters

Either is acceptable.

Do not optimize for performance yet.

The buffer only needs to support:

* insertion at the current caret position
* querying current contents for rendering

---

## Required editor state

The `TextEditor` widget should store at least:

* current text contents
* caret position
* focused state or enough integration with focus tracking
* blink visibility state
* last blink timestamp or equivalent timing info
* font/text style info if needed for rendering

### Meaning

#### text contents

The editor’s current text.

For Stage 1, this may be a single line only.
That is acceptable.

#### caret position

An integer insertion index into the current text.

For this phase:

* caret position ranges from `0` to `length(text)`

#### focused state

Whether the editor currently has focus.

This may be:

* stored directly on the widget
* or derived from global focused-widget state

Either is acceptable, as long as the editor can know whether it is focused.

#### blink visibility state

Whether the caret is currently visible or invisible for the blink cycle.

#### last blink timestamp

Used to decide when to toggle caret visibility.

---

# Part 3: Focus

## Goal

The editor must be able to receive focus.

## Required behaviour

When the editor is clicked with the left mouse button inside its rectangle:

* it becomes the focused widget

After that:

* key events should be routed to it by the existing event routing system

If your current focus system is incomplete, add the minimum needed to make this work.

---

## Required focus rule for this stage

For Stage 1, a simple focus model is enough:

* clicking inside the editor gives it focus
* clicking elsewhere may remove focus or move focus elsewhere if that already exists

It is acceptable if focus handling is still primitive, as long as:

* the editor can gain focus
* focused key events reach the editor

---

# Part 4: Event Handling

## Goal

The editor should respond to:

* mouse click for focus
* text input for character insertion
* possibly key events only as needed for this phase

---

## Required event support

Implement handling for at least:

* `:mouse-down` or click-equivalent for focus acquisition
* `:text-input`

If your current event system does not yet produce `:text-input`, you may temporarily use a simpler keyboard-to-character path, but proper text input events are preferred.

---

## Mouse handling

When the editor receives a left mouse press inside its rectangle:

* set focus to this editor
* set caret visible
* request redraw

For Stage 1, clicking does **not** need to reposition the caret based on x/y.
It is acceptable for the caret simply to move to the end of the text on focus if needed.

If easy, you may place the caret at the clicked text position, but it is not required for this stage.

---

## Text input handling

When the focused editor receives:

```lisp
(:text-input :text "a")
```

it should:

1. insert the text at the current caret position
2. advance the caret position accordingly
3. make the caret visible
4. reset the blink timer/state if needed
5. request redraw

Assume text input may contain more than one character in principle, though most test cases will likely be one character.

---

# Part 5: Rendering

## Goal

The editor must visibly show:

* its text
* its caret when focused

The rendering can be simple.

---

## Required visual structure

The editor should render:

1. its background
2. its text
3. its caret if focused and currently blink-visible

A border is optional but recommended if easy.

---

## Text rendering

For Stage 1, it is acceptable to render the editor’s content as a single line of text.

The editor does not need multiline behaviour yet.

If the current text exceeds the visible width:

* clipping is acceptable
* no scrolling is required yet

Use the existing text rendering system.

---

## Caret rendering

The caret should be drawn as a simple vertical line.

It should appear at the insertion point:

* before the first character if caret position is 0
* after the last character if caret position is at end
* between characters otherwise

The caret position should be determined from the current text and font metrics.

For Stage 1, use simple text measurement as needed to find the x position.

The caret should only be drawn when:

* the editor is focused
* blink visibility is currently on

---

# Part 6: Blinking Caret

## Goal

The caret should flash.

There is currently no animation system, so use a simple redraw-on-timer approach.

## Required behaviour

Add minimal timer/blink logic so that:

* when the editor is focused, the caret toggles visible/invisible at a fixed interval
* the UI is redrawn when the blink state changes

A simple interval such as 500 ms is acceptable.

---

## Implementation guidance

You do **not** need a full animation system.

A simple approach is enough:

* store last blink timestamp
* during main loop or a periodic UI update step, check whether enough time has passed
* if yes, toggle caret visibility and request redraw

This may redraw the whole window.
That is acceptable for this stage.

---

## Reset behaviour

Whenever text is typed or the editor gains focus:

* caret should become visible immediately
* blink timer should reset

This feels more natural.

---

# Part 7: Minimum Size

## Goal

The editor should participate in layout sensibly.

## Required minimum size

For Stage 1, a fixed minimum size is acceptable.

Example:

* minimum width: 200
* minimum height: one text line plus padding

If your system already supports text measurement nicely, the minimum height may be derived from font height plus padding.

The exact values are flexible, but the widget should be large enough to display one line of text comfortably.

---

# Part 8: Styling

## Goal

Keep the visuals simple but clear.

At minimum define:

* background color
* text color
* caret color
* maybe border color

These may be hardcoded for Stage 1 or taken from a simple style/theme system if that already exists.

The important thing is that:

* typed text is visible
* caret is visible
* focus state is visible enough to test

---

# Part 9: Interaction Rules for Stage 1

## Behaviour summary

### Click inside editor

* editor gets focus
* caret becomes visible
* redraw requested

### Type text while focused

* text inserted at caret
* caret moves forward
* caret visible
* redraw requested

### Editor not focused

* no caret shown
* text input ignored

---

# Part 10: Event Routing Requirements

## Goal

The existing event system must route text input to the focused editor.

If necessary, extend the event normalization layer to support:

```lisp
(:text-input :text "a")
```

This is strongly recommended for text entry.

Do not rely only on `:key-down` for printable text if SDL text input is available.

---

# Part 11: Testing Requirements

This phase should be testable both manually and with automated tests where practical.

## Manual tests

### 1. Focus acquisition

* create a window with a text editor widget
* click inside the editor
* verify the caret appears and blinks

### 2. Text insertion

* with the editor focused, type characters
* verify they appear on screen
* verify the caret moves right

### 3. Focus loss or non-focus behaviour

* ensure text input does not go to the editor when it is not focused

### 4. Blink behaviour

* verify the caret flashes while focused
* verify typing resets blink visibility

---

## Automated tests

### 1. Editor initial state

Create an editor and assert:

* text is initially empty
* caret position is 0
* editor is not focused by default unless your system says otherwise

### 2. Focus click

Send a click event inside the editor.
Assert that:

* editor becomes focused
* redraw is requested

### 3. Text insertion at caret

With editor focused, send text input `"a"`.
Assert:

* text becomes `"a"`
* caret position becomes 1

Then send `"b"`.
Assert:

* text becomes `"ab"`
* caret position becomes 2

### 4. Text input ignored when not focused

Send text input to an unfocused editor.
Assert text does not change.

### 5. Blink toggle logic

Simulate elapsed time and assert caret visibility toggles when focused.

### 6. Blink reset on input

After text insertion, assert:

* caret becomes visible
* blink timer/state resets

### 7. Caret index bounds

Assert caret position never goes below 0 or above text length in this phase’s supported operations.

---

# Part 12: Example Behaviour

## Example 1: Empty focused editor

Initial state:

* text = `""`
* caret position = 0
* focused = true

Render result:

* empty editor background
* blinking caret at start position

---

## Example 2: Typing “abc”

Starting from focused empty editor:

Input events:

```lisp
(:text-input :text "a")
(:text-input :text "b")
(:text-input :text "c")
```

Expected state after processing:

* text = `"abc"`
* caret position = 3

Render result:

* text “abc”
* caret just after the “c”

---

# Part 13: Out of Scope for Stage 1

Do **not** add yet:

* arrow key movement
* Backspace/Delete
* Enter/new lines
* Home/End
* mouse caret placement by x/y
* selections
* scrolling
* scrollbars
* multiline rendering
* clipboard
* syntax highlighting
* undo/redo

Keep this phase focused on:

* focus
* text entry
* visible caret
* blinking

---

# Part 14: Summary

Implement a `TextEditor` widget with:

* simple text storage
* caret position
* focus acquisition on click
* text insertion from `:text-input`
* caret rendering
* blinking caret via simple timer-based redraw

This phase should end with a usable tiny editor widget where:

* you click it
* you type text
* the text appears
* the caret flashes

That is the first milestone for the editor subsystem.
