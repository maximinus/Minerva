Below is a focused implementation spec for the next phase.

It assumes the following already exist:

* base widget/layout system
* `NinePatch`, `HBox`, `Button`, `Menu`
* overlay stack
* event routing / messaging system
* command/action emission
* button hover/pressed state
* overlays can capture input

This phase adds:

* `MenuBar`
* `MenuBarButton`
* opening a menu overlay from a menubar button
* keeping the active menubar button visually pressed while its menu is open
* closing the menu under the specified conditions

This spec keeps things simple and does **not** add:

* submenus
* keyboard navigation between menus
* click-drag across menu bar buttons to switch menus
* mnemonics / Alt-key activation
* multiple simultaneously open menus
* automatic edge-aware placement beyond whatever overlay anchoring already provides

---

# Minerva MenuBar Spec (Phase: Basic Menu Bar)

## Goal

Implement a standard GUI menu bar widget.

The menu bar should:

* render as a `NinePatch` containing an `HBox` of buttons
* open a menu overlay when a menubar button is pressed
* keep the corresponding menubar button in the pressed state while that menu is open
* close the menu when:

  * a menu item is clicked
  * Escape is pressed
  * there is a left mouse click outside the menu
* return the menubar button to normal when the menu closes

This phase is intended to produce a normal, clickable top-level menu bar.

---

# Part 1: MenuBar Structure

## Required widget

Add a `MenuBar` widget.

Conceptually its structure is:

* `NinePatch`

  * `HBox`

    * one button per top-level menu

This may be implemented literally using those widgets or via a specialized `MenuBar` widget that behaves equivalently.

Either is acceptable, but the public behaviour must match this structure.

---

## Required data model

A `MenuBar` should contain a sequence of menu definitions.

Each menu definition should include at least:

* button text
* menu contents

For example, conceptually:

* File → menu with Open / Save / Exit
* Edit → menu with Cut / Copy / Paste
* Help → menu with About

The exact constructor syntax is flexible, but it should be simple and data-driven.

---

# Part 2: MenuBar Buttons

## Goal

Each top-level menu entry is represented by a button in the menu bar.

These buttons behave slightly differently from ordinary buttons:

* when clicked, they open a menu overlay
* while their menu is open, they remain visually pressed
* clicking them should not directly emit the menu item command; instead they open/close the menu overlay
* they do not have a nine-patch and are rendered as plain text

---

## Required behaviour

Each menubar button should have:

* normal state
* hovered state
* pressed state

For each state, a different background color is used. For normal, it is 0% alpha. For hovered and pressed, it is light grey and dark grey, as defined in themes.lisp. When rendered dark grey, the label text is also set to another value in themes.lisp - set to white.

While its menu is open, it should stay in the pressed state regardless of ordinary hover logic.

This is important.

---

## Recommended implementation approach

Create a specialized `MenuBarButton`

What matters is:

* opening the menu overlay works
* the active menubar button stays pressed while the menu is open
* the visual instructions are followed

---

# Part 3: Opening a Menu Overlay

## Goal

When a menubar button is pressed, a new overlay containing the corresponding menu should be created and pushed onto the overlay stack.

## Required behaviour

When the user clicks a menubar button:

1. determine which menu definition belongs to that button
2. create the corresponding `Menu` widget
3. create an overlay for that menu
4. position the overlay just below the menubar button
5. push it onto the overlay stack
6. mark that menubar button as the active/open one
7. set redraw as needed

---

## Overlay configuration

The menu overlay should use these behaviours:

* input policy / focus mode: `:capture`
* it should close when it is a left click outisde its last-render-position
* it should close when it gets an event that the escape key was pressed

---

## Anchor rule

The menu overlay should be positioned below the button that opened it.

Use the button’s last-render-position rectangle to offset the menu (which should be below the MenuBarButton with a little - define the spacing in themes.lisp)

---

# Part 4: Tracking the Open Menu

## Goal

The system needs to know whether a menu bar menu is currently open, and if so which one.

## Required state

Add enough state to track:

* whether a menubar menu is open
* which menubar button/menu is currently active
* optionally the overlay id associated with that open menu

Suggested conceptual fields:

* `open-menu-bar-item`
* `open-menu-overlay`

Exact names are flexible.

This state may live:

* in the `MenuBar`
* in app state
* or in some UI controller state

Any of these are acceptable, as long as the behaviour is clear and centralized.

---

# Part 5: Closing a Menu

## Goal

The menu opened by the menubar should close under the required conditions.

## Required close conditions

The menu closes when:

1. a menu item is clicked
2. Escape is pressed
3. there is a left mouse click outside the menu

These are the required conditions for this phase.

---

## Required close effects

When the menu closes:

* remove its overlay from the overlay stack
* clear the active/open menubar button state
* return the menubar button to normal state
* request redraw

If a menu item was clicked, its command should still be emitted/processed normally.

---

# Part 6: Outside Click Behaviour

## Goal

The menu should close when the user left-clicks outside the menu.

## Required rule

If a left mouse click happens outside the open menu overlay:

* close the menu
* consume the click
* do not pass that same click through to the base UI or other widgets

For this phase, only left mouse click needs to trigger outside-click dismissal.

---

# Part 7: Escape Behaviour

## Goal

Pressing Escape while a menu is open should close it.

## Required rule

If Escape is pressed while the menu overlay is open:

* close the menu
* consume the event
* do not pass Escape through to lower layers or the root UI

---

# Part 8: Menu Item Click Behaviour

## Goal

Selecting a menu item should both:

* close the menu
* run the menu item’s command

## Required rule

When a menu item inside the open menu is activated:

1. close the menu overlay
2. clear active menubar button state
3. emit/process the menu item’s command

This should feel like normal desktop menu behaviour.

---

# Part 9: Rendering Behaviour

## Goal

The menu bar should render like a normal UI bar, and the active button should remain visibly pressed while its menu is open.

## Required rendering rules

### MenuBar

Render its background via `NinePatch`, then its buttons in an `HBox`.

### MenuBar buttons

Render each button normally, except:

* if its menu is the currently open one, render that button in pressed state

The pressed appearance must remain even if the mouse moves elsewhere while the menu is open.

---

# Part 10: Construction API

## Goal

The menu bar should be easy to construct from a list of menu definitions.

The exact final constructor syntax is flexible, but it should support something like:

* top-level button text
* associated menu specification

For example conceptually:

```lisp
(make-instance 'minerva.gui:menu-bar
  '(:text "File"
    :items
      ((:text "Open" :command :open)
       (:text "Save" :command :save)
       :spacer
       (:text "Exit" :command :quit)))
  '(:text "Edit"
    :items
      ((:text "Cut" :command :cut)
       (:text "Copy" :command :copy)
       (:text "Paste" :command :paste))))
```

This is only illustrative.
The implementer may use a cleaner helper constructor if preferred.

What matters is that:

* menu bar entries are data-driven
* each top-level entry maps to one menu definition

---

# Part 11: Event Handling Rules

## MenuBar button click

When a menubar button is clicked:

### If no menu is open

* open that button’s menu
* mark that button as active/open

### If that same menu is already open

For this phase, the simplest acceptable behaviour is:

* leave it open
* keep the button pressed

Do **not** add toggle-to-close.
A simple non-toggle behaviour is acceptable for now.

### If another menubar menu is open


* close old menu
* open new menu
* move pressed state to new button

---

# Part 12: Suggested Interaction Examples

## Example 1: Open File menu

User clicks “File” menubar button.

Expected result:

* File button becomes pressed
* File menu appears in an overlay below the File button
* overlay captures input

---

## Example 2: Click Save item

With File menu open, user clicks “Save”.

Expected result:

* menu closes
* File button returns to normal
* `:save` command is emitted/processed

---

## Example 3: Press Escape

With File menu open, user presses Escape.

Expected result:

* menu closes
* File button returns to normal
* no lower widget receives that Escape event

---

## Example 4: Click outside menu

With File menu open, user left-clicks somewhere outside the menu.

Expected result:

* menu closes
* File button returns to normal
* click is consumed

---

## Example 5: Switch menus

If Option A is implemented:

* File menu is open
* user clicks Edit button

Expected result:

* File menu closes
* Edit menu opens
* File button returns to normal
* Edit button becomes pressed

---

# Part 13: Tests

This phase should be testable without relying only on manual visual inspection.

## Construction tests

### 1. MenuBar can be constructed from menu definitions

Assert that the menu bar creates the correct number of top-level buttons.

### 2. Each menubar button is associated with the correct menu definition

Assert mapping is correct.

---

## Interaction tests

### 3. Clicking a menubar button opens a menu overlay

Assert:

* overlay stack grows
* overlay root widget is the expected menu
* active/open menu state is set

### 4. Open menubar button remains visually pressed

Assert that while the menu is open, the corresponding button renders as pressed.

### 5. Clicking a menu item closes the menu and emits command

Assert:

* overlay removed
* active/open menu state cleared
* command emitted

### 6. Pressing Escape closes the menu

Assert:

* overlay removed
* button no longer pressed
* event consumed

### 7. Left click outside the menu closes the menu

Assert:

* overlay removed
* button no longer pressed
* click consumed

### 8. Clicking another menubar button switches menus

If implementing menu switching:

* first menu closes
* second menu opens
* pressed state transfers correctly

---

## Rendering/layout tests

### 9. Menu overlay is anchored below the correct button

Assert overlay placement uses the button rect as anchor.

### 10. Menubar renders background and buttons in correct order

Basic rendering sanity check.

---

# Part 14: Out of Scope for This Phase

Do **not** add yet:

* submenu support
* drag-to-switch menus while holding mouse button
* keyboard navigation between menu items
* keyboard navigation across top-level menus
* Alt-key menu activation
* toggle-close behaviour unless intentionally chosen
* disabled menu items
* checkable menu items
* menubar overflow handling

Keep this phase focused on:

* displaying a top-level menu bar
* opening one menu overlay from a button
* keeping the corresponding button pressed
* closing under the specified conditions

---

# Part 15: Summary

Implement:

## New widget

* `MenuBar`

## Specialized helper/widget

* `MenuBarButton`

## New behaviour

* clicking a menubar button opens a menu overlay anchored below it
* the opened button remains visually pressed while the menu is open
* the menu closes when:

  * a menu item is clicked
  * Escape is pressed
  * a left mouse click occurs outside the menu

## Required state

* track which menubar menu/button is currently open
* track the corresponding overlay if useful

This phase should produce a normal usable menu bar with one open menu at a time.
