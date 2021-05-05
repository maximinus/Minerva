import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango

ICON_SIZE = 32
ICON_PATH = f'../resources/icons/{ICON_SIZE}px/'


def getIconPath(filename):
	return f'{ICON_PATH}{filename}.png'


class NotebookTabLabel(Gtk.EventBox):
	def __init__(self, title):
		super().__init__()
		self.btn = Gtk.Button()
		self.btn.set_image(Gtk.Image.new_from_file(getIconPath('help')))
		self.btn.set_relief(Gtk.ReliefStyle.NONE)

		#rcStyle = Gtk.RcStyle()
		#rcStyle.Xthickness = 0
		#rcStyle.Ythickness = 0
		#self.btn.ModifyStyle(rcStyle)
		#self.btn.FocusOnClick = False

		label = Gtk.Label(title)
		label.UseMarkup = False
		label.UseUnderline = False

		hbox = Gtk.HBox(False, 0)
		hbox.Spacing = 0
		hbox.add(label)
		hbox.add(self.btn)

		self.btn.show()
		label.show()
		hbox.show()

		self.add(hbox)


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

		image = Gtk.Image.new_from_file(getIconPath('start'))
		btn_run = Gtk.ToolButton(icon_widget=image, label='Run')
		toolbar.insert(btn_run, 0)

		image = Gtk.Image.new_from_file(getIconPath('bug'))
		btn_debug = Gtk.ToolButton(icon_widget=image, label='Debug')
		toolbar.insert(btn_debug, 1)

		image = Gtk.Image.new_from_file(getIconPath('outline'))
		btn_clean = Gtk.ToolButton(icon_widget=image, label='Parse')
		btn_clean.label = 'sdfsdf'
		toolbar.insert(btn_clean, 2)

		btn_run.connect('clicked', self.run_code)
		btn_debug.connect('clicked', self.debug_code)
		btn_clean.connect('clicked', self.reorder)

		toolbar.insert(Gtk.SeparatorToolItem(), 3)

		image = Gtk.Image.new_from_file(getIconPath('settings'))
		btn_settings = Gtk.ToolButton(icon_widget=image, label='Settings')
		btn_settings.connect('clicked', self.settings)
		toolbar.insert(btn_settings, 4)

	def getScrolledWindow(self):
		sw = Gtk.ScrolledWindow()
		sw.set_hexpand(True)
		sw.set_vexpand(True)

		textview = Gtk.TextView()
		textbuffer = textview.get_buffer()
		textbuffer.set_text('Empty')
		sw.add(textview)
		return sw

	def create_textview(self):
		# we want >1 scrolled windows in a tabbed view
		sw1 = self.getScrolledWindow()
		sw2 = self.getScrolledWindow()

		self.notebook = Gtk.Notebook()
		self.notebook.append_page(sw1, NotebookTabLabel('File 1'))
		self.notebook.append_page(sw2, NotebookTabLabel('File 2'))

		self.grid.attach(self.notebook, 0, 1, 3, 1)

		#self.textview = Gtk.TextView()
		#self.textbuffer = self.textview.get_buffer()
		#self.textbuffer.set_text('Empty')
		#scrolledwindow.add(self.textview)

		#self.tag_bold = self.textbuffer.create_tag('bold', weight=Pango.Weight.BOLD)

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
