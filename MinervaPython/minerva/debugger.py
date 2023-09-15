import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, Gio

from minerva.actions import get_named_action, message_queue, Target, Message


EXAMPLE_ERROR = 'The variable QWE is unbound.\n    [Condition of type UNBOUND-VARIABLE]'


class DebuggerOptions(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.pack_start(Gtk.Label(label='Lisp Debugger'), False, False, 0)
        self.error_label = Gtk.Label(label=EXAMPLE_ERROR)
        self.button_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add_buttons()

    def add_buttons(self):
        pass


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
