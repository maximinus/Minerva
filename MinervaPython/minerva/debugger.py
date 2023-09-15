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

EXAMPLE_STACK = [
    ' 0: (SB-INT:SIMPLE-EVAL-IN-LEXENV QWE #<NULL-LEXENV>)',
    ' 1: (SB-INT:SIMPLE-EVAL-IN-LEXENV (+ 1 QWE) #<NULL-LEXENV>)',
    ' 2: (EVAL (+ 1 QWE))',
    ' 3: (SWANK::EVAL-REGION "(+ 1 qwe) ..)',
    ' 4: ((LAMBDA NIL :IN SWANK-REPL::REPL-EVAL))',
    ' 5: (SWANK-REPL::TRACK-PACKAGE #<FUNCTION (LAMBDA NIL :IN SWANK-REPL::REPL-EVAL) {1002F5200B}>)',
    ' 6: (SWANK::CALL-WITH-RETRY-RESTART "Retry SLIME REPL evaluation request." #<FUNCTION (LAMBDA NIL :IN SWANK-REPL::REPL-EVAL) {1002F51FAB}>)',
    ' 7: (SWANK::CALL-WITH-BUFFER-SYNTAX NIL #<FUNCTION (LAMBDA NIL :IN SWANK-REPL::REPL-EVAL) {1002F51F8B}>)',
    ' 8: (SWANK-REPL::REPL-EVAL "(+ 1 qwe) ..)',
    ' 9: (SB-INT:SIMPLE-EVAL-IN-LEXENV (SWANK-REPL:LISTENER-EVAL "(+ 1 qwe) ..)',
    '10: (EVAL (SWANK-REPL:LISTENER-EVAL "(+ 1 qwe) ..)',
    '11: (SWANK:EVAL-FOR-EMACS (SWANK-REPL:LISTENER-EVAL "(+ 1 qwe) ..)',
    '12: (SWANK::PROCESS-REQUESTS NIL)',
    '13: ((LAMBDA NIL :IN SWANK::HANDLE-REQUESTS))',
    '14: ((LAMBDA NIL :IN SWANK::HANDLE-REQUESTS))',
    '15: (SWANK/SBCL::CALL-WITH-BREAK-HOOK #<FUNCTION SWANK:SWANK-DEBUGGER-HOOK> #<FUNCTION (LAMBDA NIL :IN SWANK::HANDLE-REQUESTS) {1002A8C02B}>)',
    '16: ((FLET SWANK/BACKEND:CALL-WITH-DEBUGGER-HOOK :IN "/home/sparky/.config/emacs/elpa/slime-20230613.1337/swank/sbcl.lisp") #<FUNCTION SWANK:SWANK-DEBUGGER-HOOK> #<FUNCTION (LAMBDA NIL :IN SWANK::HANDLE-R..',
    '17: (SWANK::CALL-WITH-BINDINGS ((*STANDARD-INPUT* . #<SWANK/GRAY::SLIME-INPUT-STREAM {10028A4B23}>)) #<FUNCTION (LAMBDA NIL :IN SWANK::HANDLE-REQUESTS) {1002A8C04B}>)',
    '18: (SWANK::HANDLE-REQUESTS #<SWANK::MULTITHREADED-CONNECTION {1001C0A2D3}> NIL)',
    '19: ((FLET SB-UNIX::BODY :IN SB-THREAD::RUN))',
    '20: ((FLET "WITHOUT-INTERRUPTS-BODY-10" :IN SB-THREAD::RUN))',
    '21: ((FLET SB-UNIX::BODY :IN SB-THREAD::RUN))',
    '22: ((FLET "WITHOUT-INTERRUPTS-BODY-3" :IN SB-THREAD::RUN))',
    '23: (SB-THREAD::RUN)',
    '24: ("foreign function: call_into_lisp")',
    '25: ("foreign function: funcall1")'
]


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


def get_tree_view(store, stack_trace):
    for i in stack_trace:
        store.append(None, [i])


class DebuggerStack(Gtk.TreeView):
    def __init__(self):
        self.store = Gtk.TreeStore(str)
        super().__init__(model=self.store)
        # design the columns and add them
        column = Gtk.TreeViewColumn('Stack Trace')
        cell_text = Gtk.CellRendererText()
        column.pack_start(cell_text, False)
        column.add_attribute(cell_text, 'text', 0)
        get_tree_view(self.store, EXAMPLE_STACK)
        self.append_column(column)
        self.set_margin_top(16)
        self.set_margin_left(16)
        self.set_margin_right(16)
        self.set_grid_lines(Gtk.TreeViewGridLines.HORIZONTAL)
        self.set_hover_selection(True)
        self.set_activate_on_single_click(False)
        self.connect('row-activated', self.row_double_click)
        self.connect('button-press-event', self.button_press)

    def row_double_click(self):
        pass

    def button_press(self, _widget, _row):
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
