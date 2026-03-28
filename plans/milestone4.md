Below is a full spec proposal for the event and command model of the Minerva GUI/editor.

It aims to keep the system:

* understandable
* easy to debug
* suitable for a Lisp codebase
* compatible with SDL
* suitable for an editor/IDE later

It does **not** assume a huge framework. The goal is a clean, minimal architecture.


# Minerva Event, Interaction, and Command Model

## Goal

Design the event system for a Lisp GUI rendered through SDL.

The system must support:

* widgets such as buttons, menus, tab bars, editors, and terminal panes
* SDL input and window events
* widget-specific interactions like clicking, hovering, focus, and typing
* application-level behaviour such as “Load File”, “Save”, “Split Pane”, etc.

The long-term target is a Lisp-based editor/IDE, but this design should start simple and scale naturally.

The architecture must be suitable for code written partly by an LLM, so it should favour:

* explicit data flow
* named commands
* simple routing rules
* minimal hidden behaviour

---

# Core Principle

There are **three different layers of events** in the system:

1. **Platform events**
   These come from SDL.

2. **UI interaction events**
   These are Minerva’s internal, normalized input events.

3. **Application actions/commands**
   These are high-level intents such as “activate button”, “open file”, “save buffer”, etc.

These must not be collapsed into one concept.

---

# High-level Pipeline

The system should process input like this:

1. SDL produces raw events
2. raw SDL events are converted into Minerva events
3. Minerva routes those events to the appropriate widget
4. widgets update local UI state and may emit actions
5. actions are dispatched as commands or model updates
6. application state changes
7. layout or redraw flags are set if needed
8. the screen is redrawn when appropriate

---

# Design Overview

## Summary of responsibilities

### SDL/backend layer

Responsible for:

* polling SDL events
* providing raw mouse/keyboard/window events
* rendering surfaces and graphics

### Event normalization layer

Responsible for:

* converting SDL event data into Minerva event objects

### UI controller layer

Responsible for:

* hit testing
* focus management
* mouse capture
* routing events to widgets
* collecting emitted actions

### Widget layer

Responsible for:

* interpreting relevant UI events
* updating widget-local state such as hover/pressed
* emitting actions/commands

### Command layer

Responsible for:

* running named application commands
* updating global app state
* triggering side effects such as loading files

### App/model layer

Responsible for:

* buffers
* panes
* tabs
* menus
* terminal sessions
* editor state
* project state

---

# 1. App State

There should be one top-level application state object.

This state object should contain at least:

* root widget tree
* focused widget id
* hovered widget id
* active/pressed widget id
* captured widget id for mouse drag/click sequences
* open buffers
* pane layout
* tabs
* terminal state
* command palette state
* menu state
* redraw/layout flags
* resource caches if needed
* global settings/theme

This state is the main source of truth.

## Why this matters

A centralized state object makes it easier to:

* debug
* inspect the current UI
* reason about command effects
* let LLM-written code interact with the system in a predictable way

---

# 2. Widget Identity

All interactive widgets should have a stable id.

Examples:

* `:load-button`
* `:save-button`
* `:main-editor`
* `:terminal-pane`
* `:menu-file`
* `:buffer-tab-12`

Widget ids should be used for:

* focus tracking
* hover tracking
* active/captured state
* logs
* testing
* action targets

## Why this matters

Do not rely on object identity or anonymous closures alone.
Explicit ids make event flow understandable.

---

# 3. Event Types

## 3.1 Platform Events (SDL-side)

These are the raw events from SDL or your backend.
Examples:

* mouse moved
* mouse button down
* mouse button up
* key down
* key up
* text input
* window resized
* quit

These should be immediately converted into Minerva events.

The rest of the application should not depend directly on SDL event shapes.

---

## 3.2 Minerva Input Events

These are the normalized internal UI/input events.

Suggested event kinds include:

* mouse-move
* mouse-down
* mouse-up
* mouse-wheel
* key-down
* key-up
* text-input
* window-resized
* quit

These should contain only the information Minerva needs.

### Example shapes

```lisp
(:mouse-move :x 120 :y 300)
(:mouse-down :button :left :x 120 :y 300)
(:mouse-up :button :left :x 120 :y 300)
(:key-down :key :escape :mods (:ctrl))
(:text-input :text "a")
(:window-resized :width 1400 :height 900)
(:quit)
```

Exact representation is flexible, but it should be:

* regular
* easy to pattern match
* easy to print in logs

---

## 3.3 Widget-Level Actions

Widgets should not directly run arbitrary system logic during input handling if possible.

Instead, widgets should emit actions.

Examples:

* `(:activate-widget :load-button)`
* `(:set-focus :main-editor)`
* `(:command :load-file)`
* `(:command :save-current-buffer)`
* `(:close-tab 4)`
* `(:select-menu :file)`
* `(:set-hover :load-button)`

Some actions are purely UI-state changes.
Some actions map to app commands.

---

## 3.4 Application Commands

Commands are named, high-level operations.

Examples:

* `:load-file`
* `:save-current-buffer`
* `:quit-app`
* `:split-pane-horizontal`
* `:focus-terminal`
* `:toggle-command-palette`

These are handled by a central command dispatcher.

Commands are the preferred way to connect:

* buttons
* menus
* keybindings
* command palette entries

to application behaviour.

---

# 4. Event Routing Model

## Principle

Do **not** broadcast every event to every widget.

Instead, route events according to:

* mouse position
* focus
* capture
* global shortcuts

This keeps the system understandable and efficient.

---

## 4.1 Mouse event routing

Mouse events should usually be routed by hit testing.

### Rule

When a mouse event happens:

1. determine which widget lies under the mouse position
2. send the event to that widget
3. unless a widget currently has mouse capture, in which case send to the captured widget

### Why capture matters

For example, button clicks usually work like:

* mouse-down inside button → button becomes active/captured
* mouse-up may still go to that button even if the pointer moved slightly

This is standard GUI behaviour.

### Mouse capture use cases

* button press/release
* dragging splitters
* sliders
* selection drags
* scrollbars later

---

## 4.2 Keyboard event routing

Keyboard events should usually go to the focused widget.

### Rule

When a key event or text input event occurs:

* route it to the focused widget

Examples:

* editor focused → typing inserts text
* terminal focused → typing sends terminal input
* button focused → Enter or Space activates button

---

## 4.3 Global shortcut handling

Some key events should be handled globally.

Examples:

* Ctrl+S
* Ctrl+P
* Ctrl+Q
* Alt+F

These do not belong only to the focused widget.

### Suggested rule

Use a small global shortcut layer before or after focused-widget routing.

Recommended default:

1. check global shortcuts first
2. if none match, send to focused widget

This is common in editors and IDEs.

---

# 5. Widget Behaviour Model

Widgets should be responsible for:

* reacting to events relevant to them
* updating their own simple interactive state if needed
* emitting actions

Widgets should **not** generally:

* perform arbitrary filesystem operations
* directly manipulate unrelated global systems
* run complex app logic inside rendering code

---

## 5.1 Buttons

A button should have:

* an id
* a label or image
* layout info
* visual state such as normal/hover/pressed/disabled
* an associated command or action to emit when activated

### Button interaction logic

A button typically responds to:

* mouse-down inside → become pressed/active
* mouse-up inside after press → emit activate action or command
* mouse-move → update hover state
* keyboard focus activation (Enter/Space) → emit command

### Example

A Load button might be defined with:

* id: `:load-button`
* command: `:load-file`

When clicked, the button emits:

```lisp
(:command :load-file)
```

The button itself does not know how to load a file.

---

## 5.2 Menus and menu items

Menus follow the same principle.

A menu item might emit:

```lisp
(:command :save-current-buffer)
```

Again, menu item code should not directly implement save behaviour.

---

## 5.3 Editor and terminal widgets

These are special widgets and will have richer event handling.

For example:

* editor widget consumes keyboard/text input
* terminal widget consumes keyboard/text input
* both may emit commands or update model state directly through well-defined APIs

But they should still fit the same outer model:

* receive routed events
* return actions and state changes
* do not bypass the architecture unnecessarily

---

# 6. Command System

## Principle

Application behaviour should live in named commands.

A command is a named operation that can be triggered by:

* button click
* menu item
* keybinding
* command palette
* maybe later scripts/macros

This is one of the most important architectural choices.

---

## 6.1 Why use commands instead of arbitrary widget callbacks?

Because commands are:

* easier to log
* easier to search for
* easier to test
* easier to bind from multiple UI sources
* more understandable to humans
* more predictable for LLM-generated code

---

## 6.2 Command dispatcher

There should be a central dispatcher that:

* receives a command name and optional arguments
* finds the corresponding implementation
* runs it with access to app state/context

Example conceptual flow:

```lisp
(:command :load-file)
```

becomes:

* dispatch command `:load-file`
* command implementation updates app state and/or performs side effects

---

## 6.3 Command implementation location

Commands should live in a clear module, not hidden inside widgets.

Examples:

* `commands/files.lisp`
* `commands/panes.lisp`
* `commands/editor.lisp`

Or one central file at first if simpler.

The important thing is that command implementations are easy to find.

---

# 7. Event Loop

## Goal

The main loop should be short and understandable.

A good high-level loop is:

1. poll platform events
2. normalize them into Minerva events
3. route each event
4. collect actions
5. dispatch actions/commands
6. run layout if needed
7. redraw if needed
8. wait for next event or tick

---

## 7.1 Recommended redraw policy

Do not redraw continuously unless needed.

Use flags:

* `needs-redraw`
* `needs-layout`

When state changes:

* set redraw flag
* set layout flag too if the change affects geometry

Then:

* run layout if `needs-layout`
* redraw if `needs-redraw`

This is efficient and simple.

---

## 7.2 Suggested event loop behaviour in prose

When the app is idle, it waits for input.
When an input event arrives:

* it is converted to an internal event
* the event is routed to the right widget or global handler
* widgets may emit actions
* actions are processed
* the state may change
* if visual state changed, redraw is requested
* if layout changed, layout is recomputed before redraw

---

# 8. Hit Testing

Hit testing determines which widget is under a mouse position.

## Rule

Widgets that can receive mouse input should participate in hit testing.

Usually the routing algorithm should:

* walk the widget tree from top/root
* descend into children
* find the deepest widget whose rectangle contains the mouse point
* respect z-order if overlapping widgets ever exist

For the current system, a simple tree descent is enough.

---

# 9. Focus Management

Focus determines which widget gets keyboard input.

## Focus rules

* clicking an interactive widget may give it focus
* some widgets are focusable, some are not
* only one widget is focused at a time

Examples:

* editor pane is focusable
* terminal pane is focusable
* button may be focusable
* simple decorative container is not focusable

The app state should track:

* current focused widget id

---

# 10. Message/Action Queue

A simple action queue is recommended.

## Why

It decouples:

* event handling
  from
* app logic execution

This means widgets can emit actions without immediately mutating everything themselves.

### Example

Button receives click.
Button emits:

```lisp
(:command :load-file)
```

This is pushed to the queue.
The dispatcher later processes it.

This is simpler than a global event bus and less magical than arbitrary callbacks.

---

# 11. Examples

## Example 1: Clicking the Load button

### Setup

The widget tree includes a button:

* id: `:load-button`
* command: `:load-file`

### User action

User clicks on the button.

### Flow

1. SDL emits mouse-down
2. Minerva normalizes it:

   ```lisp
   (:mouse-down :button :left :x 80 :y 20)
   ```
3. UI controller hit-tests `(80,20)` and finds `:load-button`
4. Button receives mouse-down and becomes pressed
5. Later SDL emits mouse-up
6. Minerva normalizes it:

   ```lisp
   (:mouse-up :button :left :x 80 :y 20)
   ```
7. Button sees it was pressed and released inside its bounds
8. Button emits:

   ```lisp
   (:command :load-file)
   ```
9. Command dispatcher runs `:load-file`
10. The load-file command opens a dialog or loads a file
11. App state updates
12. `needs-redraw` is set
13. UI redraws

---

## Example 2: Typing into the editor

### Setup

Focused widget is `:main-editor`.

### User action

User types the letter `a`.

### Flow

1. SDL emits text input
2. Minerva normalizes it:

   ```lisp
   (:text-input :text "a")
   ```
3. UI controller sends text input to focused widget `:main-editor`
4. Editor widget processes text input
5. Editor emits action like:

   ```lisp
   (:insert-text-into-buffer :buffer-id 12 :text "a")
   ```

   or directly updates the editor model through a structured API
6. Buffer changes
7. `needs-redraw` is set
8. UI redraws

---

## Example 3: Ctrl+S global shortcut

### User action

User presses Ctrl+S.

### Flow

1. SDL emits key-down
2. Minerva normalizes it:

   ```lisp
   (:key-down :key :s :mods (:ctrl))
   ```
3. Global shortcut layer matches Ctrl+S
4. It emits:

   ```lisp
   (:command :save-current-buffer)
   ```
5. Command dispatcher runs save logic

No button or editor widget had to know about the shortcut itself.

---

# 12. Recommended Default Rules

These should be adopted unless a specific feature requires otherwise.

## Rule 1

SDL events are normalized immediately.

## Rule 2

Do not broadcast all events to all widgets.

## Rule 3

Mouse events are routed by hit testing and capture.

## Rule 4

Keyboard and text input go to the focused widget.

## Rule 5

Global shortcuts are handled centrally.

## Rule 6

Widgets emit actions/commands instead of directly performing arbitrary system logic.

## Rule 7

Named commands are the main way to trigger application behaviour.

## Rule 8

The event loop is short and only orchestrates the phases.

## Rule 9

Rendering should be side-effect-free where possible.

## Rule 10

Use stable widget ids for all interactive widgets.

---

# 13. What Not To Do

## Do not:

* pass every event to every widget
* let widgets directly call arbitrary app code all over the place
* let rendering mutate unrelated app state
* mix SDL event structures into the whole codebase
* hide command logic in anonymous callbacks everywhere

These choices make the system harder to follow and harder for LLM-generated code to stay coherent.

---

# 14. Minimal Implementation Strategy

A minimal first implementation can be very small.

## Required pieces

1. internal event representation
2. focused widget id in app state
3. hover/pressed widget tracking
4. hit-test function
5. button widget event handler
6. action queue
7. command dispatcher
8. top-level event loop that uses these pieces

With just that, you can already support:

* buttons
* menus
* keyboard shortcuts
* focused editor widget later

---

# 15. Suggested First Widgets to Implement Under This Model

* Button
* MenuBar / MenuItem
* File list or simple list widget
* Editor pane
* Terminal pane

All of these can fit the same architecture.

---

# 16. Summary

Minerva should use:

* raw SDL events only at the backend boundary
* internal normalized events everywhere else
* routed events, not broadcast events
* focus for keyboard
* hit testing/capture for mouse
* widget-emitted actions
* a central named command dispatcher
* a short event loop
* redraw-on-change

This gives a system that is:

* easy to inspect
* easy to log
* easy to test
* suitable for editor/IDE features later
* understandable for humans even when code is partly generated by an LLM

---

# Short version

A button should not directly “do anything magical.”
It should be clicked, emit `(:command :load-file)`, and the command system should do the rest.

Mouse events go to the widget under the mouse.
Keyboard events go to the focused widget.
Global shortcuts are handled centrally.
Everything else follows from that.
