import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango

from pathlib import Path

COLOR_RED = '#FF8888'
COLOR_BLUE = '#8888FF'

VERSION = '0.02'

# TODO:
# * Add menubar with icons and shortcuts; understand
# * Add toolbar with icons and tooltips
# * Add text editing window
# * change font in textview
# Add a repl window at the bottom
# * Add a results thing at the bottom
# * Add messagebox on all non-working links
# Add HTML view on help menu
# * Add proper about box
# * Add save and load menus for text, and they work
# Allow to close a buffer from the tab
# Show errors in example code
# * Add custom icons for menu
# Add custom icons for toolbar


MENU_DATA = """
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='FileNew' />
      <menuitem action='FileOpen' />
      <menuitem action='FileSave' />
      <separator />
      <menuitem action='FileQuit' />
    </menu>
    <menu action='LispMenu'>
      <menuitem action='LispRun' />
      <menuitem action='LispDebug' />
    </menu>
    <menu action='HelpMenu'>
      <menuitem action='HelpHelp'/>
      <separator />
      <menuitem action='HelpAbout'/>
    </menu>
  </menubar>
  <toolbar name='ToolBar'>
    <toolitem action='FileNew' />
    <toolitem action='FileOpen' />
    <toolitem action='FileSave' />
  </toolbar>
</ui>
"""

# write our menu in Json: convert to Lisp later
MENUS = [{'text': 'File',
          'items': [{'text': 'New', 'icon': 'new', 'shortcut': '<Control>n'},
                    {'text': 'Open', 'icon': 'open', 'shortcut': '<Control>o'},
                    {'text': 'Save', 'icon': 'save', 'shortcut': '<Control>s'},
                    {'text': '-'},
                    {'text': 'Quit', 'icon': 'quit', 'shortcut': '<Control>q'}]},
         {'text': 'Lisp',
          'items': [{'text': 'Run', 'icon': 'run', 'shortcut': 'F5'},
                    {'text': 'Debug', 'icon': 'debug', 'shortcut': 'F6'}]},
         {'text': 'Help',
          'items': [{'text': 'Help',  'icon': 'help', 'shortcut': 'F1'},
                    {'text': '-'},
                    {'text': 'About', 'icon': 'debug'}]}]


class TextBuffer:
    def __init__(self, text_view, filename=None):
        self.text_view = text_view
        self.filename = filename
        self.saved = False
        if filename is not None:
            self.saved = True

    def get_label(self):
        if self.filename is None:
            display_name = 'empty'
        else:
            display_name = self.filename.name
        if self.saved:
            return get_label(display_name, COLOR_BLUE)
        return get_label(f'<i>{display_name}</i>', COLOR_RED)

    def save_file(self, window):
        # if the filename exists, just save it there
        if self.filename is not None:
            filename = self.filename
        else:
            filename = self.get_filename(window)
            if filename is None:
                # no filename selected
                return
        with open(filename, 'w') as file:
            buffer = self.text_view.get_buffer()
            start = buffer.get_start_iter()
            end = buffer.get_end_iter()
            file.write(buffer.get_text(start, end, True))
        if self.filename is None:
            self.filename = filename
        self.saved = True

    def get_filename(self, window):
        dialog = Gtk.FileChooserDialog(title="Select file", parent=window, action=Gtk.FileChooserAction.SAVE)
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_SAVE, Gtk.ResponseType.OK)
        dialog.set_do_overwrite_confirmation(True)
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            filename = Path(dialog.get_filename())
        else:
            filename = None
        dialog.destroy()
        return filename


def get_label(html_text, color=None):
    # return a label with markup
    label = Gtk.Label()
    if color is None:
        label.set_markup(html_text)
    else:
        label.set_markup(f'<span color="{color}">{html_text}</span>')
    return label


def get_menu_from_config(accel_group):
    # get our own menubar
    menu_bar = Gtk.MenuBar()
    for menu_item in MENUS:
        new_menu = Gtk.Menu()
        menu_top = Gtk.MenuItem(menu_item['text'])
        menu_top.set_submenu(new_menu)
        for menu_choice in menu_item['items']:
            if menu_choice['text'] == '-':
                new_menu.append(Gtk.SeparatorMenuItem())
                continue
            else:
                if 'icon' in menu_choice:
                    menu_item = Gtk.ImageMenuItem(label=menu_choice['text'])
                    image = Gtk.Image()
                    image.set_from_file('./gfx/icons/save.png')
                    menu_item.set_image(image)
                else:
                    menu_item = Gtk.MenuItem(label=menu_choice['text'])
                if 'shortcut' in menu_choice:
                    key, mod = Gtk.accelerator_parse(menu_choice['shortcut'])
                    menu_item.add_accelerator('activate', accel_group, key, mod, Gtk.AccelFlags.VISIBLE)
                new_menu.append(menu_item)
        menu_bar.append(menu_top)
    return menu_bar


class MinervaWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Minerva Lisp IDE")

        # add a simple menu
        self.set_default_size(800, 600)

        #action_group = Gtk.ActionGroup(name="my_actions")

        #self.add_file_menu_actions(action_group)
        #self.add_lisp_menu_actions(action_group)
        #self.add_help_menu_actions(action_group)

        #ui_manager = self.create_ui_manager()
        #ui_manager.insert_action_group(action_group)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        #menubar = ui_manager.get_widget("/MenuBar")

        self.accel_group = Gtk.AccelGroup()
        self.add_accel_group(self.accel_group)
        box.pack_start(get_menu_from_config(self.accel_group), False, False, 0)

        #toolbar = ui_manager.get_widget("/ToolBar")
        #box.pack_start(toolbar, False, False, 0)

        self.notebook = Gtk.Notebook()
        self.buffers = []
        page_data = self.create_textview()
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


    def create_textview(self, text=None):
        # textview needs to go into a scrolled window of course
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.set_hexpand(True)
        scrolled_window.set_vexpand(True)

        text_view = Gtk.TextView()
        text_view.override_font(Pango.FontDescription('inconsolata 12'))
        if text is None:
            text_view.get_buffer().set_text('')
        else:
            text_view.get_buffer().set_text(text)

        scrolled_window.add(text_view)
        return [scrolled_window, text_view]

    def create_ui_manager(self):
        ui_manager = Gtk.UIManager()
        # Throws exception if something went wrong
        ui_manager.add_ui_from_string(MENU_DATA)
        # Add the accelerator group to the toplevel window
        accel_group = ui_manager.get_accel_group()
        self.add_accel_group(accel_group)
        return ui_manager

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
        lisp_menu = Gtk.Action(name='LispMenu', label='Lisp')
        action_group.add_action(lisp_menu)

        lisp_run = Gtk.Action(name='LispRun', label='Run')
        lisp_run.connect('activate', self.messagebox, 'Not programmed yet')
        action_group.add_action_with_accel(lisp_run, 'F5')

        lisp_debug = Gtk.Action(name='LispDebug', label='Debug')
        lisp_debug.connect('activate', self.messagebox, 'Not programmed yet')
        action_group.add_action_with_accel(lisp_debug, 'F6')

    def add_help_menu_actions(self, action_group):
        help_menu = Gtk.Action(name='HelpMenu', label='Help')
        action_group.add_action(help_menu)

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
            page_data = self.create_textview(text=text)
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
