import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, Pango

from enum import Enum


class Keys(Enum):
    RETURN = 65293
    CURSOR_UP = 65362
    CURSOR_DOWN = 65364
    CURSOR_LEFT = 65361
    CURSOR_RIGHT = 65363
    BACKSPACE = 65288
    DELETE = 65535


TAGS = ['line-start']

# unicode charaters = offsets
# byte count = indexes


class Console:
    def __init__(self):
        self.text_view = Gtk.TextView()
        self.buffer = self.text_view.get_buffer()
        self.line_end = Gtk.TextMark.new('line-start', True)
        self.setup_text_view()
        self.history = []
        self.history_index = -1

    def setup_text_view(self):
        self.text_view.override_font(Pango.FontDescription('inconsolata 12'))
        self.buffer.set_text('> ')
        end_pos = self.buffer.get_end_iter()
        self.buffer.place_cursor(end_pos)
        # put a mark here for the start of the line
        # True = Left gravity, mark is moved left
        self.buffer.add_mark(self.line_end, end_pos)
        self.text_view.connect('key-press-event', self.key_press)

    def key_press(self, _widget, event):
        if event.keyval == Keys.RETURN.value:
            self.handle_input()
            return True
        if event.keyval == Keys.CURSOR_UP.value:
            self.show_history(-1)
            return True
        if event.keyval == Keys.CURSOR_DOWN.value:
            self.show_history(1)
            return True
        if event.keyval == Keys.CURSOR_LEFT.value:
            return self.check_left()
        return False

    def show_history(self, direction):
        pass

    def check_left(self):
        # if the cursor is on the line_start tag, then return False
        # we should flash the screen or something to inform the user
        cursor_pos = self.buffer.get_iter_at_mark(self.buffer.get_insert())
        mark_pos = self.buffer.get_iter_at_mark(self.buffer.get_mark('line-start'))
        # is there a tag at this position?
        if cursor_pos.equal(mark_pos):
            return True
        return False

    def process(self, command):
        # process the command and return the response
        response = 'Error: Could not find SBCL binary'
        return response

    def handle_input(self):
        # return has been pressed, so execute the statment
        # grab the current line the cursor is on
        # print it
        line_start_pos = self.buffer.get_iter_at_mark(self.buffer.get_mark('line-start'))
        end_line_pos = self.buffer.get_end_iter()
        # grab the text between the iters
        line_text = self.buffer.get_slice(line_start_pos, end_line_pos, False)
        response = self.process(line_text)
        # insert new text to the end of the buffer, move the cursor and set the line start again
        new_text = f'\n> {response}\n> '
        self.buffer.insert(end_line_pos, new_text)
        new_end = self.buffer.get_end_iter()
        self.buffer.place_cursor(new_end)
        # remove the mark
        self.buffer.delete_mark(self.line_end)
        # and move it back to the where we are now
        self.buffer.add_mark(self.line_end, new_end)
