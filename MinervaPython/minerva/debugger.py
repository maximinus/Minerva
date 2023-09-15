import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from minerva.logs import logger
from minerva.helpers.images import get_image
from minerva.actions import get_named_action, message_queue, Target, Message


EXAMPLE_ERROR = '<b>The variable QWE is unbound.\n    [Condition of type UNBOUND-VARIABLE]</b>'

EXAMPLE_BUTTONS = ['[CONTINUE] Retry using QWE.',
                   '[USE-VALUE] Use specified value.',
                   '[STORE-VALUE] Set specified value and use it.',
                   '[RETRY] Retry SLIME REPL evaluation request.',
                   "[*ABORT] Return to SLIME's top level.",
                   '[ABORT] abort thread (#<THREAD "repl-thread" RUNNING {1002A70913}>)']

EXAMPLE_STACK = []


class DebuggerOptions(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.set_margin_left(16)
        self.set_margin_right(16)
        self.error_label = Gtk.Label()
        self.error_label.set_use_markup(True)
        self.error_label.set_label(EXAMPLE_ERROR)
        self.error_label.set_halign(Gtk.Align.START)
        self.error_label.set_margin_top(16)
        self.error_label.set_margin_bottom(8)
        self.button_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add_buttons(EXAMPLE_BUTTONS)
        self.pack_start(self.error_label, False, False, 0)
        self.pack_start(self.button_box, False, False, 0)

    def add_buttons(self, buttons):
        for child in self.button_box.get_children():
            self.button_box.remove(child)
        # the buttons need to be the same size
        # they need an image on the left hand side
        # they should be left aligned
        for index, text in enumerate(buttons):
            new_button = Gtk.Button()
            new_button.set_label(text)
            new_button.set_image(get_image(f'debugger/button_{index+1}.png'))
            new_button.set_always_show_image(True)
            new_button.set_relief(Gtk.ReliefStyle.NONE)
            new_button.set_halign(Gtk.Align.FILL)
            new_button.set_alignment(0.0, 0.5)
            self.button_box.pack_start(new_button, False, False, 0)


class DebuggerStack(Gtk.TreeView):
    def __init__(self):
        self.store = Gtk.TreeStore(str)
        super().__init__(model=self.store)
        # design the columns and add them
        column = Gtk.TreeViewColumn('Stack Trace')
        column.pack_start(Gtk.CellRendererText(), False)
        self.append_column(column)
        self.set_margin_top(16)
        self.set_margin_left(16)
        self.set_margin_right(16)
        self.treeview.set_activate_on_single_click(False)
        self.treeview.connect('row-activated', self.row_double_click)
        self.treeview.connect('button-press-event', self.button_press)

    def row_double_click(self):
        pass

    def button_press(self):
        pass


class Debugger(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        # consists of 2 things split by a pane; both are in a scrolled window
        # left side is a simple box with the options to select from
        # right side is a tree display of the stack trace: a box with a label
        box.pack_start(DebuggerOptions(), False, False, 0)
        box.pack_start(DebuggerStack(), True, True, 0)
        self.add(box)

    def message(self, message):
        # this is a message we need to handle
        match message.action:
            case _:
                logger.error(f'Debugger cannot understand action {message.action}')
