import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from pathlib import Path


ABOUT_FILE = Path('./glade/about.glade')


class AboutDialog:
    def __init__(self):
        self.builder = Gtk.Builder()
        self.builder.add_from_file(str(ABOUT_FILE))
        self.builder.connect_signals(self)
        self.dialog = self.builder.get_object('about')

    def show(self):
        self.dialog.show_all()
        self.dialog.run()
        self.dialog.hide()

    def close_dialog(self, _widget):
        self.dialog.response(0)
