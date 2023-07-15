import json
import os
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path


PREFERENCES_FILE = Path('./glade/preferences.glade')
DEFAULT_CONFIG_FILE = Path('./config/minerva.config')


class Config:
    def __init__(self):
        self.valid = True
        self.editor_font = None
        self.repl_font = None
        self.lisp_binary = None
        self.load_config_file()

    def load_config_file(self):
        # load the file, or create if it does not exist
        if not os.path.isfile(DEFAULT_CONFIG_FILE):
            self.create_default_config()
        try:
            with open(DEFAULT_CONFIG_FILE, 'r') as read_file:
                data = json.load(read_file)
            self.editor_font = data['editor_font']
            self.repl_font = data['repl_font']
            self.lisp_binary = data['lisp_binary']
        except (ValueError, OSError):
            # could not load the file
            self.valid = False

    def create_default_config(self):
        self.editor_font = None
        self.repl_font = None
        self.lisp_binary = '/usr/bin/sbcl'
        self.update()

    def update(self):
        data = {'editor_font': self.editor_font,
                'repl_font': self.repl_font,
                'lisp_binary': self.lisp_binary}
        # save the config fie as values have changed
        with open(DEFAULT_CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)


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

    def set_editor_font(self, widget):
        # get the font
        config.editor_font = widget.get_font_name()
        config.update()

    def set_repl_font(self, widget):
        config.repl_font = widget.get_font_name()
        config.update()

    def lisp_binary_chosen(self, widget):
        config.lisp_binary = widget.get_file().get_path()
        config.update()

    def close_dialog(self, _widget):
        self.dialog.response(0)


config = Config()
preferences_dialog = PreferencesDialog()


def show_preferences():
    preferences_dialog.show()