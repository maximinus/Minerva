Below is a focused implementation spec for the next phase.

It assumes the following already exist:

* layout engine
* event normalization/routing
* widget event handlers
* action emission / command path
* widgets such as `Image`, `Label`, `NinePatch`, `HBox`, `VBox`
* button-like hover handling concepts
* basic menu-related rendering primitives such as text, images, nine-patch backgrounds

This phase adds:

* `MenuItem`
* `MenuSpacer`
* `Menu`

This phase does **not** add:

* menu bar
* nested submenus
* keyboard navigation
* shortcut execution from the key text
* checked items
* disabled items
* tear-off menus
* positioning relative to screen edges
* pop-up logic from other widgets

The goal is to build a normal vertical drop-down menu widget and test the event/layout/rendering model with it.

---

# Minerva Menu and MenuItem Spec (Phase: Basic Drop-down Menu)

## Goal

Implement a basic GUI drop-down menu widget.

The menu should:

* visually resemble a normal GUI menu
* be built from existing widgets and layout primitives where practical
* contain menu items and separators
* highlight menu items on mouse-over
* emit the command associated with a menu item when clicked

The menu is a standalone widget in this phase.
There is no menu bar yet.

---

# Overview

This phase introduces three new widget concepts:

* `MenuItem`
* `MenuSpacer`
* `Menu`

A `Menu` is visually:

* a `NinePatch`
* containing a `VBox`
* whose children are `MenuItem` and `MenuSpacer`

A `MenuItem` is visually:

* a horizontal layout row
* with three logical columns:

  1. optional icon
  2. main label text
  3. optional key text

A `MenuSpacer` is visually:

* a small horizontal grey line
* with vertical padding above and below it

The menu item label text and key text should line up vertically across all items in the same menu.

This means the menu needs some internal column alignment logic.

---

# Design Principles

## 1. A menu is a container widget, not a special global system

For this phase, `Menu` is just another widget:

* it has a layout rectangle
* it renders itself
* it receives mouse events
* its children receive routed events

Do not introduce a special global popup manager yet.

---

## 2. Menu items emit commands, they do not perform actions directly

Like buttons, menu items should emit:

```lisp
(:command <something>)
```

They should not directly quit the app, save files, etc.

---

## 3. Column alignment is a menu-level responsibility

The icon column, label column, and key column should line up across all menu items.

This should not be left to each `MenuItem` independently.

The `Menu` should determine shared column widths and use them consistently when laying out its items.

This is important.

---

## 4. Keep the API simple and data-oriented

The menu should be constructible from a simple description of items.

The exact final API may differ slightly from the user example, but it should support the same ideas:

* text
* command
* optional icon
* optional key text
* spacer entries

---

# Part 1: New Widget Types

Implement these new widget classes:

* `MenuItem`
* `MenuSpacer`
* `Menu`

---

# Part 2: MenuItem

## Purpose

A `MenuItem` represents one clickable row in a menu.

It contains:

* optional icon
* main text
* optional key text
* hover/highlight behaviour
* associated command

It is an interactive widget.

---

## Required properties

A `MenuItem` should have at least:

* `id` (optional but recommended)
* `text`
* `command`
* `icon` (optional)
* `key-text` (optional)
* `highlighted-color`
* normal background color or normal rendering state
* interaction state (`normal` / `hovered`)
* references to internal child widgets if needed
* any normal layout properties already required by the system

### Meaning of properties

#### `text`

Main label text, for example:

* `"Open"`
* `"Save"`
* `"Exit"`

#### `command`

The action emitted when activated.
Examples:

* `(:open)`
* `(:save)`
* `(:quit)`

If the surrounding system expects `(:command ...)`, then the `MenuItem` can emit:

```lisp
(:command (:open))
```

or

```lisp
(:command :open)
```

Pick one convention and use it consistently.

#### `icon`

Optional icon identifier or image resource key.

For this phase, assume the icon is something that can be turned into an `Image` widget or looked up as a surface.

#### `key-text`

Optional text displayed on the right side, for example:

* `"Ctrl-X"`
* `"F5"`

This is display-only in this phase.

#### `highlighted-color`

Background color used when the mouse is over the menu item.

---

## Visual structure

Conceptually, a `MenuItem` is a single row with three columns:

1. icon column
2. label column
3. key-text column

The icon is optional.
The key text is optional.

The key-text should be rendered in a lighter color than the main label text.

---

## Rendering behaviour

A `MenuItem` should render:

* normal background when not hovered
* `highlighted-color` background when hovered

Then render:

* optional icon in the icon column
* main text in the label column
* optional lighter key text in the key column

Text vertical alignment should be visually reasonable.
Exact typographic perfection is not required for this phase.

---

## Interaction behaviour

A `MenuItem` should respond to:

* `:mouse-move`
* `:mouse-down`
* `:mouse-up`

### Hover

When the mouse is inside the item:

* state becomes hovered

When outside:

* state becomes normal

### Activation

On left mouse click inside:

* emit the configured command action

Use the same basic click rule as buttons:

* mouse-down inside marks it active/pressed if needed
* mouse-up inside same item activates

This can reuse or mirror button interaction logic.

For this phase, if a simpler direct “mouse-up inside while hovered” activation is already the easiest consistent path, that is acceptable, but standard button-like click behaviour is preferred.

---

# Part 3: MenuSpacer

## Purpose

A `MenuSpacer` is a non-interactive visual separator inside a menu.

It appears as:

* some vertical space
* a small grey horizontal line
* some vertical space

It is not clickable.

---

## Required properties

A `MenuSpacer` should have at least:

* line color (default grey is fine)
* top spacing
* bottom spacing
* line height or thickness
* maybe left/right inset if useful

Defaults are acceptable.

---

## Minimum size

A `MenuSpacer` should report a small minimum height based on:

* top spacing
* line thickness
* bottom spacing

Its width should expand to fill the menu content width.

---

## Rendering behaviour

Render:

* transparent or menu-background-compatible area
* one horizontal grey line centered vertically within the spacer’s row

The line should not necessarily touch the full width if a small inset looks better.

---

## Interaction behaviour

Ignore all events.

`MenuSpacer` should never emit commands.

---

# Part 4: Menu

## Purpose

A `Menu` is a vertical list of menu items and spacers, rendered inside a nine-patch background.

It is a container widget.

---

## Visual structure

A `Menu` is:

* outer `NinePatch`
* containing a `VBox`
* whose children are `MenuItem` and `MenuSpacer`

This may be implemented literally using those widgets or via a specialized container implementation that behaves equivalently.

Either approach is acceptable, but the public behaviour must match this structure.

---

## Required properties

A `Menu` should have at least:

* background nine-patch or menu surface/border definition
* child items
* maybe padding/content insets via the nine-patch
* menu-wide text style info if useful
* menu-wide lighter key-text color if useful
* menu-wide column width cache or measurement results

---

## Child content

A menu may contain:

* `MenuItem`
* `MenuSpacer`

No other child types are required in this phase.

---

## Construction API

The menu should be constructible from a simple list-like description.

The exact Lisp constructor syntax may vary, but it should support the following ideas:

### Desired user-facing style

Something approximately like:

```lisp
(make-instance 'minerva.gui:menu
  '(:text "open" :command (:open) :icon "open")
  '(:text "save" :command (:save) :icon "save")
  :spacer
  '(:text "exit" :command (:quit) :key "Ctrl-X"))
```

This exact syntax does not have to be used if it is awkward, but the API should support equivalent input.

### Required semantics

The constructor or helper should accept entries that are either:

* menu item descriptions
* spacer markers

A helper constructor may be preferable, for example:

* `make-menu`
* or a parser from menu entry descriptions

That is acceptable.

---

# Part 5: Menu Layout Rules

## Goal

All menu item columns should align across the entire menu.

This means:

* icon column widths must be shared
* label column widths must be shared
* key-text column widths must be shared

The `Menu` should compute these widths from its child items.

---

## Column model

The menu should behave as if every `MenuItem` has these columns:

* icon column
* gap
* label column
* gap / stretch
* key column

### Icon column

Width should be the maximum icon width used by any menu item in this menu.
If an item has no icon, it still reserves that column width so labels align.

### Label column

Width should be the maximum label width among menu items, unless the menu/item design already makes label area expand naturally.
The important requirement is that all labels start at the same x-position and all key texts line up to the right in a consistent way.

### Key column

Width should be the maximum key-text width among items that have key text.

### Spacer rows

A `MenuSpacer` should simply fill available width and does not participate as a text/icon row.

---

## Minimum size of Menu

The menu’s minimum size should be based on:

* the nine-patch borders
* the `VBox` internal content size
* the computed shared column widths
* the total heights of menu items and spacers

In practice:

* the content width should be sufficient for the aligned columns
* the content height should be the sum of row heights

---

# Part 6: MenuItem Internal Layout

## Goal

Even though `MenuItem` is conceptually an `HBox`, its columns must align with sibling items.

The simplest design is:

* the `Menu` computes shared column widths
* each `MenuItem` uses those widths when laying out its internal parts

Do not let each `MenuItem` independently choose its own icon/text/key widths.

---

## Implementation strategies

###  MenuItem stores internal child widgets

For example:

* optional image widget
* label widget
* key label widget

Then `MenuItem` lays them out using menu-provided column widths.

The image used in the image widget is guarenteed to be the same size for every menu item. The key label text should align right, and the hbox holding all this and the label widget should both have expand-x set to true.

---

# Part 7: Event Handling

## Menu

A `Menu` itself is mostly a container.
It should:

* pass events to the correct child via normal routing
* not itself emit commands except perhaps later for dismissal logic, which is out of scope now

## MenuItem

A `MenuItem` is interactive.

It should:

* highlight on mouse-over
* emit its command on activation

Its event handling should follow the same general pattern as buttons.

## MenuSpacer

Ignores events.

---

# Part 8: Visual Styling Rules

## Main text

Render in normal menu text color.

## Key text

Render in a slightly lighter color than the main text.

This should be visibly distinct but still readable.

Use a menu-level default if practical.

## Hover background

When a menu item is hovered, draw its `highlighted-color` as background.

## Normal background

When not hovered, use the menu background or transparent row over the menu panel, whichever matches the existing rendering style better.

Do not overcomplicate this phase with pressed/disabled states unless they come for free.

---

# Part 9: Example Behaviour

## Example menu content

Semantically, this menu contains:

1. Open

   * icon: open
   * command: open

2. Save

   * icon: save
   * command: save

3. spacer

4. Exit

   * no icon
   * command: quit
   * key text: Ctrl-X

---

## Example layout expectations

* all label texts begin at the same x-position
* all key texts begin at the same x-position or right-aligned in a shared key column
* iconless rows still reserve icon column width so label alignment remains correct
* spacer occupies a full row between items

---

## Example interaction expectations

When the mouse moves over “Save”:

* Save row background changes to `highlighted-color`
* other rows are not highlighted

When the user clicks “Exit”:

* menu item emits its configured command action
* for example:

  ```lisp
  (:command (:quit))
  ```

  or

  ```lisp
  (:command :quit)
  ```

  depending on chosen convention

---

# Part 10: Suggested Construction Model

## Goal

Support a convenient constructor from item descriptions.

A helper constructor is recommended.

### Suggested helper

Something conceptually like:

* `make-menu`

It could accept a variable number of entries.

Entries may be:

* plist describing a menu item
* the symbol `:spacer`

### Example

Conceptually:

```lisp
(make-menu
  '(:text "open" :command :open :icon "open")
  '(:text "save" :command :save :icon "save")
  :spacer
  '(:text "exit" :command :quit :key "Ctrl-X"))
```

This is only an example.
The implementer may choose a slightly different Lisp API if it is cleaner, but it must support the same expressive power.

---

# Part 11: Required Tests

This phase should be testable without relying only on manual visual inspection.

## MenuItem tests

### 1. MenuItem stores text, command, icon, and key-text correctly

Construct a menu item and verify its properties.

### 2. MenuItem hover changes visual state

Send a mouse-move inside its rectangle.
Assert state becomes hovered.

### 3. MenuItem mouse move outside returns to normal

Send a mouse-move outside its rectangle.
Assert state becomes normal.

### 4. MenuItem click emits command

Perform mouse-down + mouse-up inside the item.
Assert that the correct command action is emitted.

### 5. MenuItem without icon still works

Construct without icon.
Assert layout/render logic still succeeds.

### 6. MenuItem without key-text still works

Construct without key text.
Assert layout/render logic still succeeds.

---

## MenuSpacer tests

### 7. MenuSpacer has sensible minimum height

Assert its minimum size reflects line thickness and vertical spacing.

### 8. MenuSpacer ignores events

Send it mouse events.
Assert no action is emitted and state does not change.

---

## Menu layout tests

### 9. Menu computes consistent shared icon column width

Create menu items with icons of different widths.
Assert that all item label positions line up.

### 10. Menu items without icons still align their labels correctly

Create some rows with icons and some without.
Assert label text columns align.

### 11. Menu computes consistent shared key column width

Create items with different key-text lengths.
Assert key text positions line up consistently.

### 12. Menu minimum width includes widest needed columns

Assert that the menu content width is wide enough for aligned icon/label/key columns.

### 13. Spacer occupies a full row between menu items

Assert spacer is present in the correct vertical position and takes row space.

---

## Rendering tests

### 14. Hovered menu item uses highlighted background color

Render or inspect draw behaviour for hovered and non-hovered states.

### 15. Key text uses lighter color than main text

Assert that the rendering path for key text uses the alternate lighter text color.

### 16. Menu renders nine-patch background and then child content

Assert rendering order and structure are correct.

---

## Event routing tests

### 17. Mouse events route to the correct menu item by hit test

Given a menu with several rows, assert that mouse coordinates over each row route to the right item.

### 18. Clicking one menu item does not trigger adjacent items

Assert hit testing and activation are row-specific.

---

# Part 12: Out of Scope for This Phase

Do not add yet:

* menu bar
* submenus
* checked/ticked items
* disabled items
* keyboard navigation inside menu
* auto-dismiss logic on outside click
* scrollable menus
* menu positioning logic relative to other widgets
* mnemonic underlines
* accelerator execution from key text
* icons generated dynamically by command system

Keep this phase focused on:

* menu rendering
* menu item interaction
* spacer rows
* aligned columns
* command emission

---

# Part 13: Summary

Implement:

## New widgets

* `MenuItem`
* `MenuSpacer`
* `Menu`

## MenuItem behaviour

* optional icon
* main label
* optional key text
* lighter color for key text
* highlight on hover
* emit command on click

## MenuSpacer behaviour

* grey horizontal line
* vertical spacing
* non-interactive

## Menu behaviour

* nine-patch background
* vertical list of children
* shared icon/label/key column alignment
* constructible from a simple description format

This phase should result in a working standalone drop-down menu widget that can later be connected to a menu bar or popup system.
