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

# TODO:
# Does not get larger when adding text
# When clicked, cursor can only go to the bottom line


class Console:
    def __init__(self):
        self.widget = Gtk.ScrolledWindow()
        self.widget.set_hexpand(True)
        self.widget.set_vexpand(True)
        self.text_view = Gtk.TextView()
        self.widget.add(self.text_view)
        self.buffer = self.text_view.get_buffer()
        self.line_end = Gtk.TextMark.new('line-start', True)
        self.setup_text_view()
        self.history = []
        self.history_index = 0

    def setup_text_view(self):
        self.text_view.override_font(Pango.FontDescription('inconsolata 12'))
        self.buffer.set_text('* SBCL 2.1.11\n* ')
        end_pos = self.buffer.get_end_iter()
        self.buffer.place_cursor(end_pos)
        # put a mark here for the start of the line
        # True = Left gravity, mark is moved left
        self.buffer.add_mark(self.line_end, end_pos)
        self.text_view.connect('key-press-event', self.key_press)
        self.text_view.connect('button-press-event', self.clicked)
        self.text_view.connect('size-allocate', self.autoscroll)

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
        # self.history is a list of previous commands
        # history[-1] is the most recent, and history[0] is the most recent
        # if there is no history, do nothing
        if len(self.history) == 0:
            return True
        index_to_show = self.history_index + direction
        if index_to_show < 0 or index_to_show >= len(self.history):
            # out of bounds
            return True
        # set the new index
        self.history_index = index_to_show
        # delete everything after line-start
        start_iter = self.buffer.get_iter_at_mark(self.buffer.get_mark('line-start'))
        self.buffer.delete(start_iter, self.buffer.get_end_iter())
        # add command from line-start
        self.buffer.insert(start_iter, self.history[self.history_index])
        # place cursor at end of buffer
        new_end = self.buffer.get_end_iter()
        self.buffer.place_cursor(new_end)

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
        self.history.append(command)
        # point tht index at this most recent + 1
        self.history_index = len(self.history)
        response = 'Error: Could not find SBCL binary'
        return response

    def handle_input(self):
        # return has been pressed, so execute the statement
        # grab the current line the cursor is on
        # print it
        line_start_pos = self.buffer.get_iter_at_mark(self.buffer.get_mark('line-start'))
        end_line_pos = self.buffer.get_end_iter()
        # grab the text between the iters
        line_text = self.buffer.get_slice(line_start_pos, end_line_pos, False)
        response = self.process(line_text)
        # insert new text to the end of the buffer, move the cursor and set the line start again
        new_text = f'\n* {response}\n* '
        self.buffer.insert(end_line_pos, new_text)
        new_end = self.buffer.get_end_iter()
        self.buffer.place_cursor(new_end)
        # remove the mark
        self.buffer.delete_mark(self.line_end)
        # and move it back to the where we are now
        self.buffer.add_mark(self.line_end, new_end)

    def clicked(self, _widget, event):
        # get the positions of the line_start and end iters
        start_iter = self.buffer.get_iter_at_mark(self.buffer.get_mark('line-start'))
        end_iter = self.buffer.get_end_iter()
        while start_iter != end_iter:
            start_pos = self.text_view.get_iter_location(start_iter)
            xpos = self.text_view.buffer_to_window_coords(Gtk.TextWindowType.WIDGET, start_pos.x, start_pos.y)[0]
            if xpos >= event.x:
                # put the cursor here and we are done
                self.buffer.place_cursor(start_iter)
                self.text_view.grab_focus()
                return True
            # move along characters
            if start_iter.forward_char() is False:
                # hit end of text, so exit the loop
                break
        # no match, so put the cursor at the end
        self.buffer.place_cursor(end_iter)
        # make the text view active
        self.text_view.grab_focus()
        return True

    def autoscroll(self, *args):
        # the text area size has got bigger (we added more text)
        # so make sure to scroll to the bottom
        adj = self.widget.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())
