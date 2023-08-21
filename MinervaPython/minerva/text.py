import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango, Gdk

from pathlib import Path
from minerva.logs import logger
from minerva.actions import message_queue, Target, Message
from minerva.helpers import messagebox_yes_no

COLOR_RED = '#FF8888'
COLOR_BLUE = '#8888FF'

NOTEBOOK_LABEL_MARGIN = 2


def get_name_label(html_text, color=None):
    # return a label with markup
    label = Gtk.Label()
    if color is None:
        label.set_markup(html_text)
    else:
        label.set_markup(f'<span color="{color}">{html_text}</span>')
    return label


class TextOverlay(Gtk.Window):
    # an overlay to put over the text showing predictive text
    def __init__(self, parent):
        super().__init__(Gtk.WindowType.POPUP)
        self.set_visible(False)
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_transient_for(parent)
        self.set_resizable(False)
        self.set_halign(Gtk.Align.START)
        self.set_valign(Gtk.Align.START)
        geo_hints = Gdk.Geometry()
        geo_hints.min_width = 0
        geo_hints.min_height = 0
        self.set_geometry_hints(None, geo_hints, Gdk.WindowHints.MIN_SIZE)
        self.lines = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.lines.set_orientation(orientation=Gtk.Orientation.VERTICAL)
        self.lines.set_halign(Gtk.Align.START)
        self.lines.set_valign(Gtk.Align.START)
        self.lines.get_style_context().add_class('code_hint_box')
        # add the example lines
        self.add_single_line('defclass name (super) (slot) options', selected=True)
        self.add_single_line('defmacro name (args ...) form')
        self.add_single_line('defun name (args ...)')
        self.add(self.lines)

    def add_single_line(self, text, selected=False):
        new_label = Gtk.Label()
        new_label.set_markup(f'<span font_desc="Mono Normal 10">{text}</span>')
        new_label.set_halign(Gtk.Align.FILL)
        new_label.set_valign(Gtk.Align.START)
        new_label.set_xalign(0.0)
        if selected:
            new_label.get_style_context().add_class('autocomplete_selected')
        else:
            new_label.get_style_context().add_class('autocomplete_not_selected')
        self.lines.pack_start(new_label, False, False, 0)


class TextBuffer:
    window_decoration_height = 0

    def __init__(self, text_view, code_hint, filename=None):
        self.text_view = text_view
        self.code_hint = code_hint
        self.filename = filename
        self.saved = False
        # this means we have been loaded, so also currently saved
        if filename is not None:
            self.saved = True
        # we need callbacks when we gain and lose keyboard focus
        self.text_view.connect('focus-in-event', self.gained_focus)
        self.text_view.connect('focus-out-event', self.lost_focus)
        # TODO: Connect to cursor-moved event in the buffer, not the textview
        self.text_view.get_buffer().connect('notify::cursor-position', self.cursor_moved)

    def gained_focus(self, _event, _data):
        self.set_code_hint_window()

    def lost_focus(self, _event, _data):
        # always hide the codehint window
        self.code_hint.hide()

    def cursor_moved(self, _buffer, _params):
        # ideally we want to let the event handle itself and THEN update the window
        self.set_code_hint_window()

    def set_code_hint_window(self):
        # update window decoration offset if not computed
        if self.window_decoration_height == 0:
            gdk_window = self.text_view.get_window(Gtk.TextWindowType.WIDGET)
            s1 = gdk_window.get_frame_extents().height
            s2 = self.text_view.get_toplevel().get_allocation().height
            self.window_decoration_height = s1 - s2
        window_pos = self.get_window_position()
        self.code_hint.move(window_pos[0], window_pos[1])
        self.code_hint.show_all()

    def get_window_position(self):
        # return the position the code hint window should be in
        root = self.text_view.get_toplevel()
        win_pos = root.get_position()
        widget_pos = self.text_view.translate_coordinates(root, 0, 0)
        # [0] is for the strong cursor
        foo = self.text_view.get_cursor_locations(None)
        cursor = self.text_view.get_cursor_locations(None)[0]
        # we always want the window to be over the line below what we are typing
        pos = self.text_view.buffer_to_window_coords(Gtk.TextWindowType.TEXT, cursor.x, cursor.y)
        # add window position + cursor position + cursor height
        height = win_pos[1] + widget_pos[1] + pos[1] + self.window_decoration_height + cursor.height
        return [win_pos[0] + widget_pos[0] + pos[0], height]

    def get_label(self):
        # this is actually a box
        # on the left, a text view of the file
        # on the right, an icon to close the window
        head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)

        # get the components
        if self.filename is None:
            display_name = 'empty'
        else:
            display_name = self.filename.name
        if self.saved:
            name_label = get_name_label(display_name, COLOR_BLUE)
        else:
            name_label = get_name_label(f'<i>{display_name}</i>', COLOR_RED)
        name_label.set_margin_right(NOTEBOOK_LABEL_MARGIN)
        name_label.set_xalign(0.0)
        name_label.set_yalign(0.4)

        image = Gtk.Image()
        image.set_from_file(f'./gfx/icons/close_tiny.png')
        button = Gtk.Button()
        button.set_image(image)
        button.set_alignment(1.0, 0.5)
        button.set_relief(Gtk.ReliefStyle.NONE)
        button.set_focus_on_click(False)

        # this needs a callback
        button.connect('clicked', self.button_clicked)

        head.pack_start(name_label, False, False, 0)
        head.pack_start(button, False, False, 0)
        head.show_all()
        return head

    def button_clicked(self, button):
        # send a message to close the buffer
        message_queue.message(Message(Target.BUFFERS, 'close_buffer', self))

    def save_file(self, window):
        # if the filename exists, just save it there
        if self.filename is not None:
            filename = self.filename
        else:
            filename = self.get_filename(window)
            if filename is None:
                # no filename selected
                return
        with open(filename, 'w') as file:
            buffer = self.text_view.get_buffer()
            start = buffer.get_start_iter()
            end = buffer.get_end_iter()
            file.write(buffer.get_text(start, end, True))
        if self.filename is None:
            self.filename = filename
        logger.info(f'Saved file to {filename}')
        self.saved = True

    def get_filename(self, window):
        dialog = Gtk.FileChooserDialog(title="Select file", parent=window, action=Gtk.FileChooserAction.SAVE)
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_SAVE, Gtk.ResponseType.OK)
        dialog.set_do_overwrite_confirmation(True)
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            filename = Path(dialog.get_filename())
        else:
            filename = None
        dialog.destroy()
        return filename

    def close(self):
        # call before we remove this buffer
        # return True if we want to close
        if self.saved is True:
            # nothing to do, and save is ok
            return True
        # get parent window
        parent = self.text_view.get_toplevel()
        # if we are saved and not modified, no need to ask
        if self.filename is None:
            # Nothing has been defined
            if messagebox_yes_no(parent, 'Save empty buffer?') is False:
                return True
            # save as expected, if cancelled then return False
            self.save_file(parent)
            if self.saved:
                return True
            return False
        if self.saved is False:
            # have filename but not saved
            path_file = Path(self.filename)
            if messagebox_yes_no(parent, f'Save to {path_file.name}?') is True:
                self.save_file(parent)
            return True

    def update_font(self, new_font):
        self.text_view.override_font(Pango.FontDescription(new_font))


def create_text_view(font, text=None):
    # textview needs to go into a scrolled window of course
    scrolled_window = Gtk.ScrolledWindow()
    scrolled_window.set_hexpand(True)
    scrolled_window.set_vexpand(True)

    text_view = Gtk.TextView()
    text_view.override_font(Pango.FontDescription(font))
    if text is None:
        text_view.get_buffer().set_text('')
    else:
        text_view.get_buffer().set_text(text)

    scrolled_window.add(text_view)
    return [scrolled_window, text_view]


class Buffers:
    def __init__(self):
        self.buffer_list = []
        # current page being shown
        self.current_page = 0

    def add_buffer(self, new_buffer):
        self.buffer_list.append(new_buffer)

    def update_font(self, new_font):
        for i in self.buffer_list:
            i.update_font(new_font)

    def get_index(self, index):
        return self.buffer_list[index]

    def get_current(self):
        return self.buffer_list[self.current_page]

    def close_buffer(self, buffer):
        # find this matching buffer
        index = 0
        for i in self.buffer_list:
            if i == buffer:
                if i.close():
                    # tell main window to close notebook
                    self.buffer_list.pop(index)
                    message_queue.message(Message(Target.WINDOW, 'close_notebook', index))
                # either way we are done with the buffer
                return
            index += 1

    def message(self, message):
        if message.action == 'update_font':
            self.update_font(message.data)
        elif message.action == 'close_buffer':
            self.close_buffer(message.data)
        else:
            logger.error(f'Buffers cannot understand action {message.action}')
