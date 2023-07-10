import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango

from pathlib import Path


COLOR_RED = '#FF8888'
COLOR_BLUE = '#8888FF'


def get_name_label(html_text, color=None):
    # return a label with markup
    label = Gtk.Label()
    if color is None:
        label.set_markup(html_text)
    else:
        label.set_markup(f'<span color="{color}">{html_text}</span>')
    return label


class TextBuffer:
    def __init__(self, text_view, filename=None):
        self.text_view = text_view
        self.filename = filename
        self.saved = False
        if filename is not None:
            self.saved = True

    def get_label(self):
        if self.filename is None:
            display_name = 'empty'
        else:
            display_name = self.filename.name
        if self.saved:
            return get_name_label(display_name, COLOR_BLUE)
        return get_name_label(f'<i>{display_name}</i>', COLOR_RED)

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


def create_text_view(text=None):
    # textview needs to go into a scrolled window of course
    scrolled_window = Gtk.ScrolledWindow()
    scrolled_window.set_hexpand(True)
    scrolled_window.set_vexpand(True)

    text_view = Gtk.TextView()
    text_view.override_font(Pango.FontDescription('inconsolata 12'))
    if text is None:
        text_view.get_buffer().set_text('')
    else:
        text_view.get_buffer().set_text(text)

    scrolled_window.add(text_view)
    return [scrolled_window, text_view]
