import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, Gio
from pathlib import Path

from minerva.constants.keycodes import Keys
from minerva.menu import get_menu_from_config
from minerva.toolbar import Toolbar
from minerva.text import TextEdit
from minerva.console import Console
from minerva.about import AboutDialog
from minerva.swank import SwankClient
from minerva.preferences import config
from minerva.tree_panel import SidePanel
from minerva.logs import logger, handler
from minerva.projects import ProjectWindow
from minerva.helpers.messagebox import messagebox
from minerva.preferences import PreferencesDialog
from minerva.actions import get_named_action, message_queue, Target, Message


VERSION = '0.1'
ROOT_DIRECTORY = Path().resolve()


def action_router(_caller, action, data=None):
    # turn the toolbar and file actions into messages
    message_parts = action.split(':')
    if len(message_parts) != 2:
        logger.error(f'Got bad action: {action}, with data {data}')
        return
    address = get_named_action(message_parts[0])
    command = message_parts[1]
    if address is None:
        logger.error(f'Incorrect address: {address}, with command {command}')
        return
    message_queue.message(Message(address, command, data))


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
        # self.buffers = Buffers()
        self.lisp_repl = SwankClient(ROOT_DIRECTORY, config.get('lisp_binary'))
        message_queue.set_resolver(self.resolver)
        self.lisp_repl.swank_init()
        self.connect('key-press-event', self.key_pressed)

        # Note this size does NOT include window decorations
        win_size = config.get('window_size')
        self.set_default_size(win_size[0], win_size[1])

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.accel_group = Gtk.AccelGroup()
        self.add_accel_group(self.accel_group)
        box.pack_start(get_menu_from_config(self.accel_group, action_router), False, False, 0)
        self.toolbar = Toolbar(action_router)
        box.pack_start(self.toolbar, False, False, 0)

        self.panel = Gtk.Paned(orientation=Gtk.Orientation.VERTICAL)
        # the top of the panel is another panel which is horizontal
        # left is a notebook with 2 trees
        # right is the text editor
        self.tree_panel = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        self.side_panel = SidePanel()
        self.text_editors = TextEdit(self, self.toolbar.search_toolbar)

        self.side_panel.get_style_context().add_class('sidebar_fix')
        self.tree_panel.pack1(self.side_panel, True, True)
        self.tree_panel.pack2(self.text_editors, True, True)
        self.tree_panel.set_position(256)

        self.panel.pack1(self.tree_panel, True, True)

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

        self.add(box)
        self.preferences = PreferencesDialog()
        self.about = AboutDialog()
        logger.info('Finished setup')
        # show the project window
        self.startup = ProjectWindow()
        message_queue.message(Message(Target.SWANK, 'start-swank'))

    def key_pressed(self, _widget, event):
        if event.keyval == Keys.ESCAPE.value:
            # escape closes the current search
            self.toolbar.search_toolbar.hide_search()
        # pass the event on
        return False

    def display(self):
        self.show_all()
        self.toolbar.search_toolbar.hide_search()

    def resolver(self, message):
        # pass messages on to the correct area
        match message.address:
            case Target.WINDOW:
                # that's us
                self.message(message)
            case Target.TEXT:
                self.text_editors.message(message)
            case Target.CONSOLE:
                self.console.message(message)
            case Target.SWANK:
                self.lisp_repl.message(message)
            case Target.TREES:
                self.side_panel.message(message)
            case Target.TOOLBAR:
                self.toolbar.message(message)
            case _:
                logger.error(f'No target for message to {message.action}')

    def quit_minerva(self):
        handler.close()
        # send close message to swank
        self.lisp_repl.stop_listener()
        Gtk.main_quit()

    def run_code(self):
        messagebox(self, 'Running code')

    def debug_code(self):
        messagebox(self, 'Debugging code')

    def show_help(self):
        messagebox(self, 'This is the help')

    def show_about(self):
        self.about.show()

    def show_preferences(self):
        self.preferences.show()

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
        match message.action:
            case 'close-notebook':
                self.close_notebook(message.data)
            case 'quit-minerva':
                self.quit_minerva()
            case 'display':
                self.display()
            case 'init-project':
                self.load_project(message.data)
            case 'show-preferences':
                self.show_preferences()
            case _:
                logger.error(f'Window cannot understand action {message.action}')

    def load_project(self, new_project):
        name = new_project.project_name
        directory = new_project.directory
        logger.info(f'Loading {name} from {directory}')
        self.side_panel.file_tree.scan_directory(directory)
        title = f'{self.get_title()} - {name}'
        self.set_title(title)
        self.display()


def exit_app(app):
    message_queue.message(Message(Target.SWANK, 'kill-threads'))
    logger.info('Exiting Minerva')
    app.quit_minerva()


def get_gtk_version():
    return f'Gtk v{Gtk.get_major_version()}.{Gtk.get_minor_version()}.{Gtk.get_micro_version()}'


if __name__ == '__main__':
    logger.info(f'Running Minerva v{VERSION} in Gtk {get_gtk_version()}')
    load_css_provider()
    app = MinervaWindow()
    app.connect('destroy', exit_app)
    Gtk.main()
