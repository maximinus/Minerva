import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango


class TextViewWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title='Minerva Python Demo')

        self.set_default_size(400, 350)

        self.grid = Gtk.Grid()
        self.add(self.grid)

        self.create_textview()
        self.create_toolbar()

    def create_toolbar(self):
        toolbar = Gtk.Toolbar()
        self.grid.attach(toolbar, 0, 0, 3, 1)

        btn_run = Gtk.ToolButton()
        btn_run.set_label('Run')
        btn_run.set_icon_name('format-text-bold-symbolic')
        toolbar.insert(btn_run, 0)

        btn_debug = Gtk.ToolButton()
        btn_debug.set_label('Debug')
        btn_debug.set_icon_name('format-text-italic-symbolic')
        toolbar.insert(btn_debug, 1)

        btn_clean = Gtk.ToolButton()
        btn_debug.set_label('Re-Order')
        btn_clean.set_icon_name("format-text-underline-symbolic")
        toolbar.insert(btn_clean, 2)

        btn_run.connect('clicked', self.run_code)
        btn_debug.connect('clicked', self.debug_code)
        btn_clean.connect('clicked', self.reorder)

        toolbar.insert(Gtk.SeparatorToolItem(), 3)

        btn_settings = Gtk.ToolButton()
        btn_settings.set_icon_name('edit-clear-symbolic')
        btn_settings.connect('clicked', self.settings)
        toolbar.insert(btn_settings, 4)

    def create_textview(self):
        scrolledwindow = Gtk.ScrolledWindow()
        scrolledwindow.set_hexpand(True)
        scrolledwindow.set_vexpand(True)
        self.grid.attach(scrolledwindow, 0, 1, 3, 1)

        self.textview = Gtk.TextView()
        self.textbuffer = self.textview.get_buffer()
        self.textbuffer.set_text('Empty')
        scrolledwindow.add(self.textview)

        self.tag_bold = self.textbuffer.create_tag('bold', weight=Pango.Weight.BOLD)

    def run_code(self, _button):
        print('Run code')

    def debug_code(self, _button):
        print('Debug code')

    def reorder(self, _button):
        print('Reorder')

    def settings(self, _button):
    	print('Settings')

    def on_search_clicked(self, widget):
        print("I'll search for that!")


win = TextViewWindow()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
