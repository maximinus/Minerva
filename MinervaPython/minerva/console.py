import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango


class Console:
    def __init__(self):
        self.text_view = Gtk.TextView()
        self.text_view.override_font(Pango.FontDescription('inconsolata 12'))
        self.text_view.get_buffer().set_text('> ')
        self.text_view.connect('key-press-event', self.key_press)

    def key_press(self, _widget, event):
        if event.keyval == 65293:
            self.handle_input()
            return True
        return False

    def handle_input(self):
        # return has been pressed, so execute the statment
        print('Return has been pressed')
