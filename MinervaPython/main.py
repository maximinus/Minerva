import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path

from minerva.menu import get_menu_from_config
from minerva.toolbar import get_toolbar_from_config
from minerva.text import TextBuffer, create_text_view, Buffers
from minerva.actions import get_action, add_window_actions, message_queue, Target
from minerva.console import Console
from minerva.searchbar import SearchBar
from minerva.preferences import PreferencesDialog
from minerva.logs import logger, handler
from minerva.preferences import config
from minerva.about import AboutDialog
from minerva.helpers import messagebox
from minerva.swank import SwankClient


VERSION = '0.02'
ROOT_DIRECTORY = Path().resolve()

# TODO:
# Allow REPL to be hidden
# Improve the statusbar to show text position
# Add HTML view on help menu
# When last buffer is removed, keep the notebook size
# Show errors in example code
# open a REPL with SBCL and use the console


def action_router(caller, action, data=None):
    function = get_action(action)
    if function is not None:
        if data is not None:
            function(kwargs=data)
        else:
            function()


class MinervaWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Minerva Lisp IDE")
        logger.info('Starting Minerva GUI')
        self.buffers = Buffers()
        self.lisp_repl = SwankClient(ROOT_DIRECTORY, config.lisp_binary)
        message_queue.set_resolver(self.resolver)
        self.lisp_repl.swank_init()

        self.set_default_size(800, 600)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.accel_group = Gtk.AccelGroup()
        self.add_accel_group(self.accel_group)
        box.pack_start(get_menu_from_config(self.accel_group, action_router), False, False, 0)

        self.search = SearchBar(get_toolbar_from_config(action_router))
        box.pack_start(self.search.box, False, False, 0)

        # console and notebook need to be in a pane
        self.notebook = Gtk.Notebook()
        page_data = create_text_view(config.editor_font)
        self.buffers.add_buffer(TextBuffer(page_data[1]))
        self.notebook.append_page(page_data[0], self.buffers.get_index(-1).get_label())
        # add callback for change of text view
        self.notebook.connect('switch_page', self.switch_page)
        self.console = Console(config.repl_font)
        panel = Gtk.Paned(orientation=Gtk.Orientation.VERTICAL)
        panel.pack1(self.notebook, True, True)
        panel.pack2(self.console.widget, True, True)
        box.pack_start(panel, True, True, 0)

        # This status bar actually needs to hold more than just messages
        # Add the cursor position on the RHS somehow
        self.status = Gtk.Statusbar()
        self.status_id = self.status.get_context_id("Statusbar")
        self.status.push(self.status_id, f'Minerva v{VERSION}')
        box.pack_start(self.status, False, False, 0)

        add_window_actions(self)
        self.add(box)
        self.preferences = PreferencesDialog()
        self.about = AboutDialog()
        logger.info('Finished setup')

    def resolver(self, message):
        # pass messages on to the correct area
        if message.address == Target.WINDOW:
            # that's us
            self.message(message)
        elif message.address == Target.BUFFERS:
            self.buffers.message(message)
        elif message.address == Target.CONSOLE:
            self.console.message(message)
        elif message.address == Target.SWANK:
            self.lisp_repl.message(message)
        else:
            logger.error(f'No target for message to {message.action}')

    def new_file(self):
        # add an empty notebook
        page_data = create_text_view(config.editor_font)
        self.buffers.add_buffer(TextBuffer(page_data[1]))
        self.notebook.append_page(page_data[0], self.buffers.get_index(-1).get_label())
        self.notebook.show_all()
        self.notebook.set_current_page(-1)
        self.buffers.current_page = self.notebook.get_current_page()

    def save_file(self):
        self.buffers.get_current().save_file(self)
        # we likely need to update the name on the tab
        page = self.notebook.get_nth_page(self.notebook.get_current_page())
        self.notebook.set_tab_label(page, self.buffers.get_current().get_label())

    def load_file(self):
        dialog = Gtk.FileChooserDialog(title="Select file", parent=self, action=Gtk.FileChooserAction.OPEN)
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK)

        filter_lisp = Gtk.FileFilter()
        filter_lisp.set_name('Lisp files')
        filter_lisp.add_pattern("*.lisp")
        dialog.add_filter(filter_lisp)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            filename = Path(dialog.get_filename())

            # if we already have that file, just go to the tab
            index = 0
            for i in self.buffers.buffer_list:
                if i.filename == filename:
                    self.notebook.set_current_page(index)
                    dialog.destroy()
                    return
                index += 1

            # load the file and add to the textview
            with open(filename) as f:
                text = ''.join(f.readlines())
            page_data = create_text_view(config.editor_font, text=text)
            self.buffers.add_buffer(TextBuffer(page_data[1], filename))
            self.status.push(self.status_id, f'Loaded {filename}')
            self.notebook.append_page(page_data[0], self.buffers.get_index(-1).get_label())
            # switch to the one. Must display before switching
            self.notebook.show_all()
            self.notebook.set_current_page(-1)
            self.buffers.current_page = self.notebook.get_current_page()
            logger.info(f'Loaded file from {filename}')
        dialog.destroy()

    def quit_minerva(self):
        handler.close()
        # send close message to swank
        self.lisp_repl.stop_listener()
        Gtk.main_quit()

    def run_code(self):
        messagebox('Running code')

    def debug_code(self):
        messagebox('Debugging code')

    def show_help(self):
        messagebox('This is the help')

    def show_about(self):
        self.about.show()

    def show_preferences(self):
        self.preferences.show()

    def switch_page(self, _notebook, _page, page_num):
        self.buffers.current_page = page_num

    def close_notebook(self, index):
        # remove the notebook on this index
        # no need to worry about the data by this point
        self.notebook.remove_page(index)

    def message(self, message):
        if message.action == 'close_notebook':
            self.close_notebook(message.data)
        else:
            logger.error(f'Window cannot understand action {message.action}')


def exit_app(app):
    app.quit_minerva()


if __name__ == '__main__':
    app = MinervaWindow()
    app.connect('destroy', exit_app)
    app.show_all()
    Gtk.main()
