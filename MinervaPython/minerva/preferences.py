import os
import gi
import json
import pathlib

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path

from minerva.logs import logger
from minerva.actions import message_queue, Message, Target


PREFERENCES_FILE = Path('./glade/preferences.glade')
CONFIG_DIR = pathlib.Path(__file__).parent.parent.resolve()
DEFAULT_CONFIG_FILE = CONFIG_DIR / '.' / 'config' / 'minerva.config'


class Config:
    def __init__(self):
        self.valid = True
        self.data = {}
        self.load_config_file()

    def get(self, key):
        if key in self.data:
            return self.data[key]
        else:
            return ''

    def load_config_file(self):
        # load the file, or create if it does not exist
        if not os.path.isfile(DEFAULT_CONFIG_FILE):
            self.create_default_config()
        try:
            with open(DEFAULT_CONFIG_FILE, 'r') as read_file:
                self.data = json.load(read_file)
            logger.info(f'Loaded config file at {DEFAULT_CONFIG_FILE}')
        except (ValueError, OSError, FileNotFoundError):
            # could not load the file
            logger.warning(f'Failed to load config file at {DEFAULT_CONFIG_FILE}')
            self.valid = False

    def create_default_config(self):
        self.data = {'editor_font': 'Inconsolata 12',
                     'repl_font': 'Inconsolata 12',
                     'lisp_binary': '/usr/bin/sbcl',
                     'start_repl': True}
        self.update()

    def update(self):
        # save the config fie as values have changed
        with open(DEFAULT_CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.data, f, ensure_ascii=False, indent=4)
        logger.info('Updated config file')


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
        font = widget.get_font_name()
        logger.info(f'Setting editor font to {font}')
        config.editor_font = font
        config.update()
        message_queue.message(Message(Target.BUFFERS, 'update_font', font))

    def set_repl_font(self, widget):
        font = widget.get_font_name()
        logger.info(f'Setting REPL font to {font}')
        config.repl_font = font
        config.update()
        message_queue.message(Message(Target.CONSOLE, 'update_font', font))

    def lisp_binary_chosen(self, widget):
        binary_path = widget.get_file().get_path()
        logger.info(f'Setting LISP binary to {binary_path}')
        config.lisp_binary = binary_path
        config.update()
        message_queue.message(Message(Target.CONSOLE, 'update_binary', binary_path))

    def close_dialog(self, _widget):
        self.dialog.response(0)


config = Config()
