import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from pathlib import Path

from minerva.menu import get_menu_from_config
from minerva.text import TextBuffer, create_text_view

VERSION = '0.02'

# TODO:
# Add a repl window at the bottom
# * Add a results thing at the bottom
# Add messagebox on all non-working links
# Add HTML view on help menu
# Add proper about box
# * Add save and load menus for text, and they work
# * Allow to close a buffer from the tab
# Show errors in example code
# * Add custom icons for menu
# Add custom icons for toolbar


def action_router(caller, action, data=None):
    print('Called!')


class MinervaWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Minerva Lisp IDE")

        # add a simple menu
        self.set_default_size(800, 600)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        self.accel_group = Gtk.AccelGroup()
        self.add_accel_group(self.accel_group)
        box.pack_start(get_menu_from_config(self.accel_group, action_router), False, False, 0)

        #toolbar = ui_manager.get_widget("/ToolBar")
        #box.pack_start(toolbar, False, False, 0)

        self.notebook = Gtk.Notebook()
        self.buffers = []
        page_data = create_text_view()
        self.buffers.append(TextBuffer(page_data[1]))
        self.notebook.append_page(page_data[0], self.buffers[-1].get_label())
        box.pack_start(self.notebook, True, True, 0)

        # add callback for change of text view
        self.current_page_index = 0
        self.notebook.connect('switch_page', self.switch_page)

        # This status bar actually needs to hold more than just messages
        # Add the cursor position on the RHS somehow
        self.status = Gtk.Statusbar()
        self.status_id = self.status.get_context_id("Statusbar")
        self.status.push(self.status_id, f'Minerva v{VERSION}')
        box.pack_start(self.status, False, False, 0)

        self.add(box)

    def add_file_menu_actions(self, action_group):
        file_menu = Gtk.Action(name='FileMenu', label='File')
        action_group.add_action(file_menu)

        file_new = Gtk.Action(name='FileNew', stock_id=Gtk.STOCK_NEW, tooltip='Create a new file')
        file_new.connect('activate', self.add_new_empty)
        action_group.add_action_with_accel(file_new, '<Control>n')

        file_open = Gtk.Action(name='FileOpen', stock_id=Gtk.STOCK_OPEN, tooltip='Open a file')
        file_open.connect('activate', lambda x: self.load_file())
        action_group.add_action_with_accel(file_open, '<Control>o')

        # replace the stock id
        file_save = Gtk.Action(name='FileSave', label='Save', tooltip='Save current file')
        file_save.connect('activate', self.save_file)
        action_group.add_action_with_accel(file_save, '<Control>s')

        file_quit = Gtk.Action(name='FileQuit', stock_id=Gtk.STOCK_QUIT)
        # add the callback
        file_quit.connect('activate', self.on_menu_file_quit)
        action_group.add_action_with_accel(file_quit, '<Control>q')

    def add_lisp_menu_actions(self, action_group):
        lisp_run = Gtk.Action(name='LispRun', label='Run')
        lisp_run.connect('activate', self.messagebox, 'Not programmed yet')
        action_group.add_action_with_accel(lisp_run, 'F5')

        lisp_debug = Gtk.Action(name='LispDebug', label='Debug')
        lisp_debug.connect('activate', self.messagebox, 'Not programmed yet')
        action_group.add_action_with_accel(lisp_debug, 'F6')

    def add_help_menu_actions(self, action_group):
        help_help = Gtk.Action(name='HelpHelp', stock_id=Gtk.STOCK_HELP)
        help_help.connect('activate', self.messagebox, 'Not programmed yet')
        action_group.add_action_with_accel(help_help, 'F1')

        help_about = Gtk.Action(name='HelpAbout', stock_id=Gtk.STOCK_ABOUT)
        help_about.connect('activate', self.show_about_dialog)
        action_group.add_action(help_about)

    def on_menu_file_quit(self, _caller):
        Gtk.main_quit()

    def messagebox(self, _caller, message, icon=Gtk.MessageType.INFO):
        dialog = Gtk.MessageDialog(
            transient_for=self, flags=0, message_type=icon, buttons=Gtk.ButtonsType.OK, text=message)
        dialog.run()
        dialog.destroy()

    def show_about_dialog(self, caller):
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

    def save_file(self, _caller):
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
            page_data = self.create_text_view(text=text)
            self.buffers.append(TextBuffer(page_data[1], filename))
            self.status.push(self.status_id, f'Loaded {filename}')
            self.notebook.append_page(page_data[0], self.buffers[-1].get_label())
            # switch to the one. Must display before switching
            self.notebook.show_all()
            self.notebook.set_current_page(-1)
            self.current_page_index = self.notebook.get_current_page()
        dialog.destroy()

    def add_new_empty(self, _caller):
        # add an empty notebook
        page_data = self.create_textview()
        self.buffers.append(TextBuffer(page_data[1]))
        self.notebook.append_page(page_data[0], self.buffers[-1].get_label())
        self.notebook.show_all()
        self.notebook.set_current_page(-1)
        self.current_page_index = self.notebook.get_current_page()

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
