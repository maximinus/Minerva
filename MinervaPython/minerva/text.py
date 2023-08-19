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


class TextOverlay(Gtk.Dialog):
    # an overlay to put over the text showing predictive text
    def __init__(self, parent):
        super().__init__()
        self.set_visible(True)
        self.set_decorated(False)
        self.set_transient_for(parent)
        self.lines = self.get_content_area()
        self.lines.set_orientation(orientation=Gtk.Orientation.VERTICAL)
        self.lines.margin = 2
        self.lines.set_halign(Gtk.Align.START)
        self.lines.set_valign(Gtk.Align.START)
        # add the example lines
        self.add_single_line('defclass name (super) (slot) options')
        self.add_single_line('defmacro name (args ...) form')
        self.add_single_line('defun name (args ...)')

    def add_single_line(self, text):
        new_label = Gtk.Label()
        new_label.set_markup(f'<span font_desc="Mono Normal 10">{text}</span>')
        new_label.set_halign(Gtk.Align.START)
        new_label.set_valign(Gtk.Align.START)
        self.lines.pack_start(new_label, False, False, 0)


class TextBuffer:
    def __init__(self, text_view, filename=None):
        self.text_view = text_view
        self.filename = filename
        self.saved = False
        # this means we have been loaded, so also currently saved
        if filename is not None:
            self.saved = True


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
