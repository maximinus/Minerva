import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from minerva.helpers.images import get_image
from minerva.actions import get_named_action, message_queue, Target, Message


EXAMPLE_ERROR = 'The variable QWE is unbound.\n    [Condition of type UNBOUND-VARIABLE]'

EXAMPLE_BUTTONS = ['[CONTINUE] Retry using QWE.',
                   '[USE-VALUE] Use specified value.',
                   '[STORE-VALUE] Set specified value and use it.',
                   '[RETRY] Retry SLIME REPL evaluation request.',
                   "[*ABORT] Return to SLIME's top level.",
                   '[ABORT] abort thread (#<THREAD "repl-thread" RUNNING {1002A70913}>)']


class DebuggerOptions(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.pack_start(Gtk.Label(label='Lisp Debugger'), False, False, 0)
        self.error_label = Gtk.Label(label=EXAMPLE_ERROR)
        self.button_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add_buttons(EXAMPLE_BUTTONS)

    def add_buttons(self, buttons):
        for child in self.button_box.get_children()
            self.button_box.remove(child)
        # the buttons need to be the same size
        # they need an image on the left hand side
        # they should be left aligned
        for index, text in enumerate(buttons):
            new_button = Gtk.Button()
            new_button.set_label(text)
            new_button.set_image(get_image(f'debugger/button_{index+1}'))
            new_button.set_always_show_image()
            self.button_box.pack_start(new_button, False, False)


class DebuggerStack(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)


class Debugger(Gtk.Box):
    def __init__(self):
        super().__init__()
        # consists of 2 things split by a pane; both are in a scrolled window
        # left side is a simple box with the options to select from
        # right side is a tree display of the stack trace: a box with a label
        paned = Gtk.Paned()
        left = DebuggerOptions()
        right = DebuggerStack()
