import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, Gio
from pathlib import Path

from minerva.menu import get_menu_from_config
from minerva.toolbar import get_toolbar_from_config
from minerva.text import TextBuffer, TextOverlay, create_text_view, Buffers
from minerva.actions import get_action, add_window_actions, message_queue, Target
from minerva.console import Console
from minerva.searchbar import SearchBar
from minerva.preferences import PreferencesDialog
from minerva.logs import logger, handler
from minerva.preferences import config
from minerva.about import AboutDialog
from minerva.helpers import messagebox
from minerva.swank import SwankClient


VERSION = '0.03'
ROOT_DIRECTORY = Path().resolve()

# TODO:
# show file and lisp trees on left-hand side
# show project select / start on right hand side
# remember projects and their details in a special folder
# Improve the statusbar to show text position and notices
# Add HTML view on help menu
# When last buffer is removed, keep the notebook size
# Show errors in example code
# handle REPL errors
# handle REPL disconnects / problems
# show code autocomplete on lisp
# handle indentation automatically


def action_router(caller, action, data=None):
    function = get_action(action)
    if function is not None:
        if data is not None:
            function(kwargs=data)
        else:
            function()


def load_css_provider():
    p = Gtk.CssProvider()
    p.load_from_file(Gio.file_new_for_path('./data/widgets.css'))
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


def get_action_widget():
    image = Gtk.Image()
    image.set_from_file(f'./gfx/icons/minimize.png')
    image.get_style_context().add_class('minimize_button')
    minimize = Gtk.EventBox()
    minimize.add(image)
    # action widgets are hidden by default it seems, and we must show both!
    minimize.show()
    image.show()
    return minimize


class MinervaWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Minerva Lisp IDE")
        logger.info('Starting Minerva GUI')
        self.buffers = Buffers()
        self.lisp_repl = SwankClient(ROOT_DIRECTORY, config.get('lisp_binary'))
        message_queue.set_resolver(self.resolver)
        self.lisp_repl.swank_init()

        # Note this size does NOT include window decorations
        win_size = config.get('window_size')
        self.set_default_size(win_size[0], win_size[1])

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.accel_group = Gtk.AccelGroup()
        self.add_accel_group(self.accel_group)
        box.pack_start(get_menu_from_config(self.accel_group, action_router), False, False, 0)

        self.search = SearchBar(get_toolbar_from_config(action_router))
        box.pack_start(self.search.box, False, False, 0)

        # console and notebook need to be in a pane
        self.notebook = Gtk.Notebook()
        self.code_hint_overlay = TextOverlay(self)

        page_data = create_text_view(config.get('editor_font'))
        self.buffers.add_buffer(TextBuffer(page_data[1], self.code_hint_overlay))
        self.notebook.append_page(page_data[0], self.buffers.get_index(-1).get_label())

        # add callback for change of text view
        self.notebook.connect('switch_page', self.switch_page)

        self.panel = Gtk.Paned(orientation=Gtk.Orientation.VERTICAL)

        # the top of the panel is another panel which is horizontal
        # left is a notebook with 2 trees
        self.tree_panel =

        self.panel.pack1(self.notebook, True, True)

        self.console = Console(config.get('repl_font'))
        # The console needs to be in a notebook as well
        self.bottom_notebook = Gtk.Notebook()
        self.bottom_notebook.append_page(self.console.widget, Gtk.Label(label='Lisp REPL'))
        minimize = get_action_widget()
        # add the events now
        minimize.connect('button_press_event', self.minimize_clicked)
        # old size of panel before being minimized, or -1 if not minimized
        self.minimized = -1

        self.bottom_notebook.set_action_widget(minimize, Gtk.PackType.END)
        self.bottom_notebook.set_size_request(-1, 200)
        self.panel.pack2(self.bottom_notebook, False, True)
        box.pack_start(self.panel, True, True, 0)

        # This status bar actually needs to hold more than just messages
        # Add the cursor position on the RHS somehow
        self.status = Gtk.Statusbar()
        self.status_id = self.status.get_context_id('Statusbar')
        self.status.push(self.status_id, f'Minerva v{VERSION}')
        box.pack_start(self.status, False, False, 0)

        add_window_actions(self)
        self.add(box)
        self.preferences = PreferencesDialog()
        self.about = AboutDialog()
        logger.info('Finished setup')

    def display(self):
        self.show_all()

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
        page_data = create_text_view(config.get('editor_font'))
        self.buffers.add_buffer(TextBuffer(page_data[1], self.code_hint_overlay))
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
            page_data = create_text_view(config.get('editor_font'), text=text)
            self.buffers.add_buffer(TextBuffer(page_data[1], self.code_hint_overlay, filename))
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

    def minimize_clicked(self, widget, event):
        if self.minimized < 0:
            self.minimized = self.panel.get_position()
            pane_size = self.panel.get_allocated_height()
            # notebook header size is size of notebook - size of thing inside
            notebook_size = self.bottom_notebook.get_allocated_height()
            header_size = notebook_size - self.bottom_notebook.get_nth_page(0).get_allocated_height()
            self.panel.set_position(pane_size - header_size)
        else:
            # reset to the old size
            self.panel.set_position(self.minimized)
            self.minimized = -1

    def message(self, message):
        if message.action == 'close_notebook':
            self.close_notebook(message.data)
        else:
            logger.error(f'Window cannot understand action {message.action}')


def exit_app(app):
    app.quit_minerva()


if __name__ == '__main__':
    load_css_provider()
    app = MinervaWindow()
    app.connect('destroy', exit_app)
    app.display()
    Gtk.main()
