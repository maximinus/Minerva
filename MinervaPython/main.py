import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path

from minerva.menu import get_menu_from_config
from minerva.toolbar import get_toolbar_from_config
from minerva.text import TextBuffer, create_text_view
from minerva.actions import get_action, add_window_actions
from minerva.console import Console


VERSION = '0.02'

# TODO:
# Add a repl window at the bottom
# Make REPL resizeable / hideable
# Improve the statusbar to show text position
# Add HTML view on help menu
# Allow to close a buffer from the tab
# Show errors in example code
# allow turning off icons and menus from other actions
# add a simple settings menu
# grab settings from config file
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
        self.set_default_size(800, 600)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.accel_group = Gtk.AccelGroup()
        self.add_accel_group(self.accel_group)
        box.pack_start(get_menu_from_config(self.accel_group, action_router), False, False, 0)
        box.pack_start(get_toolbar_from_config(action_router), False, False, 0)

        # console and notebook need to be in a pane
        self.notebook = Gtk.Notebook()
        self.buffers = []
        page_data = create_text_view()
        self.buffers.append(TextBuffer(page_data[1]))
        self.notebook.append_page(page_data[0], self.buffers[-1].get_label())
        # add callback for change of text view
        self.current_page_index = 0
        self.notebook.connect('switch_page', self.switch_page)
        self.console = Console()
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

    def messagebox(self, message, icon=Gtk.MessageType.INFO):
        dialog = Gtk.MessageDialog(
            transient_for=self, flags=0, message_type=icon, buttons=Gtk.ButtonsType.OK, text=message)
        dialog.run()
        dialog.destroy()

    def new_file(self):
        # add an empty notebook
        page_data = create_text_view()
        self.buffers.append(TextBuffer(page_data[1]))
        self.notebook.append_page(page_data[0], self.buffers[-1].get_label())
        self.notebook.show_all()
        self.notebook.set_current_page(-1)
        self.current_page_index = self.notebook.get_current_page()

    def save_file(self):
        self.buffers[self.current_page_index].save_file(self)
        # we likely need to update the name on the tab
        page = self.notebook.get_nth_page(self.notebook.get_current_page())
        self.notebook.set_tab_label(page, self.buffers[self.current_page_index].get_label())

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
            for i in self.buffers:
                if i.filename == filename:
                    self.notebook.set_current_page(index)
                    dialog.destroy()
                    return
                index += 1

            # load the file and add to the textview
            with open(filename) as f:
                text = ''.join(f.readlines())
            page_data = create_text_view(text=text)
            self.buffers.append(TextBuffer(page_data[1], filename))
            self.status.push(self.status_id, f'Loaded {filename}')
            self.notebook.append_page(page_data[0], self.buffers[-1].get_label())
            # switch to the one. Must display before switching
            self.notebook.show_all()
            self.notebook.set_current_page(-1)
            self.current_page_index = self.notebook.get_current_page()
        dialog.destroy()

    def quit_minerva(self):
        Gtk.main_quit()

    def run_code(self):
        self.messagebox('Running code')

    def debug_code(self):
        self.messagebox('Debugging code')

    def show_help(self):
        self.messagebox('This is the help')

    def show_about(self):
        dlg = Gtk.AboutDialog()
        dlg.set_program_name('Minerva')
        dlg.set_version(VERSION)
        dlg.set_copyright(None)
        dlg.set_license(None)
        dlg.set_website('https://github.com/maximinus/Minerva')
        image = Gtk.Image()
        image.set_from_file('./gfx/logo.png')
        dlg.set_logo(image.get_pixbuf())
        dlg.run()
        dlg.destroy()

    def switch_page(self, _notebook, _page, page_num):
        if self.current_page_index == page_num:
            # nothing to do
            return
        self.current_page_index = page_num


if __name__ == '__main__':
    app = MinervaWindow()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
