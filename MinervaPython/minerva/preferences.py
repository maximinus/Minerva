import os
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path


PREFERENCES_FILE = Path('./glade/preferences.glade')
DEFAULT_CONFIG_FILE = Path('./config/minerva.config')


class Config:
    def __init__(self):
        # load the file, or create if it does not exist
        if not os.path.isfile(DEFAULT_CONFIG_FILE):
            self.create_default_config()

    def create_default_config(self):
        pass


class PreferencesDialog:
    def __init__(self):
        self.builder = Gtk.Builder()
        self.builder.add_from_file(str(PREFERENCES_FILE))
        self.builder.connect_signals(self)
        self.dialog = self.builder.get_object('preferences')

    def show(self):
        self.dialog.show_all()
        self.dialog.run()
        self.dialog.hide()

    def set_editor_font(self, _widget):
        print(1)

    def set_repl_font(self, _widget):
        print(3)

    def config_file_chosen(self, _widget):
        print(5)

    def lisp_binary_chosen(self, _widget):
        print(6)

    def close_dialog(self, _widget):
        self.dialog.response(0)


preferences_dialog = PreferencesDialog()


def show_preferences():
    preferences_dialog.show()
