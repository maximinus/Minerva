import os

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GdkPixbuf

from pathlib import Path


class DirectoryTree:
    def __init__(self, directory):
        # saves full paths all the time
        self.dir_path = directory
        self.directories = []
        self.files = []
        self.get_directory(directory)

    def get_directory(self, directory):
        for filename in os.listdir(directory):
            fullpath = directory / filename
            if os.path.isdir(fullpath):
                self.directories.append(DirectoryTree(fullpath))
            else:
                self.files.append(fullpath)


def get_file_icons():
    root = Path(__file__).parent.parent / 'gfx' / 'file_icons'
    return [GdkPixbuf.Pixbuf.new_from_file(str(root / f'{x}.png')) for x in ['folder', 'lisp', 'text']]


def get_lisp_icons():
    root = Path(__file__).parent.parent / 'gfx' / 'lisp_icons'
    images = ['constants', 'function', 'lambda', 'variable']
    return [GdkPixbuf.Pixbuf.new_from_file(str(root / f'{x}.png')) for x in images]


def get_tree_view(store, row, new_dir, images):
    # directory paths are full paths
    if new_dir is None:
        new_dir = DirectoryTree(Path(__file__).parent.parent)
    for next_dir in new_dir.directories:
        sort_value = f'd_{next_dir.dir_path.name.lower()}'
        if row is None:
            new_row = store.append(None, [images[0], next_dir.dir_path.name, sort_value, str(next_dir.dir_path)])
        else:
            new_row = store.append(row, [images[0], next_dir.dir_path.name, sort_value, str(next_dir.dir_path)])
        get_tree_view(store, new_row, next_dir, images)

    for file in new_dir.files:
        sort_value = f'f_{file.name.lower()}'
        if file.name.endswith('lisp'):
            store.append(row, [images[1], file.name, sort_value, str(file)])
        else:
            store.append(row, [images[2], file.name, sort_value, str(file)])


def file_sort(model, row1, row2, _user_data):
    # we look at the 3rd column of each row
    # directories start with D_ and files F_; directories come first
    value1 = model.get_value(row1, 2).lower()
    value2 = model.get_value(row2, 2).lower()
    if value1 < value2:
        return -1
    return 1


class FileTreeContext(Gtk.Menu):
    def __init__(self, filepath, options, callback):
        super().__init__()
        self.filepath = filepath
        for index, option in enumerate(options):
            menu_item = Gtk.MenuItem.new_with_label(option)
            menu_item.connect('activate', callback, [index, self.filepath])
            self.append(menu_item)
        self.show_all()


class FileTree(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()
        # icon, displayed name, sort name, full filepath
        # only the first 2 are displayed
        self.store = Gtk.TreeStore(GdkPixbuf.Pixbuf, str, str, str)

        # design the columns and add them
        column = Gtk.TreeViewColumn('Filename')
        cell_text = Gtk.CellRendererText()
        cell_image = Gtk.CellRendererPixbuf()

        column.pack_start(cell_image, False)
        column.pack_start(cell_text, False)
        column.add_attribute(cell_image, 'pixbuf', 0)
        column.add_attribute(cell_text, 'text', 1)

        self.treeview = Gtk.TreeView(model=self.store)
        self.treeview.append_column(column)

        self.treeview.set_activate_on_single_click(False)
        self.treeview.connect('row-activated', self.row_double_click)
        self.treeview.connect('button-press-event', self.button_press)

        # do the calculation at the end
        get_tree_view(self.store, None, None, get_file_icons())

        # set up scrolled window
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.add(self.treeview)

    def row_double_click(self, path, column, _data):
        # TODO: Open this if it is a file
        print('Open menu')

    def button_press(self, widget, event):
        # run the models default button handler
        # connect after does not seem to work for some reason
        widget.do_button_press_event(widget, event)
        # was it a right click?
        if event.button == 3:
            iter = self.treeview.get_selection().get_selected()[1]
            if(self.store[iter][2].startswith('d_')):
                # it's a folder, so ignore
                return True
            filename = self.store[iter][1]
            filepath = self.store[iter][3]
            # show the pop-up menu
            options = [f'Open {filename}', f'Rename {filename}', f'Delete {filename}']
            context_menu = FileTreeContext(filepath, options, self.context_selected)
            context_menu.popup_at_pointer()
        return True

    def context_selected(self, widget, data):
        # TODO: Based on the data, perform action on this widget
        print(f'Selected!: {data}')


def get_tree_view(store, images):
    # for the moment this is all fake
    root ->


    for next_dir in new_dir.directories:
        sort_value = f'd_{next_dir.dir_path.name.lower()}'
        if row is None:
            new_row = store.append(None, [images[0], next_dir.dir_path.name, sort_value, str(next_dir.dir_path)])
        else:
            new_row = store.append(row, [images[0], next_dir.dir_path.name, sort_value, str(next_dir.dir_path)])
        get_tree_view(store, new_row, next_dir, images)

    for file in new_dir.files:
        sort_value = f'f_{file.name.lower()}'
        if file.name.endswith('lisp'):
            store.append(row, [images[1], file.name, sort_value, str(file)])
        else:
            store.append(row, [images[2], file.name, sort_value, str(file)])


class Lisptree(Gtk.ScrolledWindow):
    def __init__(self):
        self.store = Gtk.TreeStore(GdkPixbuf.Pixbuf, str)

        # design the columns and add them
        column = Gtk.TreeViewColumn('Namespace')
        cell_image = Gtk.CellRendererPixbuf()
        cell_text = Gtk.CellRendererText()

        column.pack_start(cell_image, False)
        column.pack_start(cell_text, False)
        column.add_attribute(cell_image, 'pixbuf', 0)
        column.add_attribute(cell_text, 'text', 1)

        self.treeview = Gtk.TreeView(model=self.store)
        self.treeview.append_column(column)

        self.treeview.set_activate_on_single_click(False)
        self.treeview.connect('row-activated', self.row_double_click)
        self.treeview.connect('button-press-event', self.button_press)

        # do the calculation at the end
        get_lisp_view(self.store, None, None, get_lisp_icons())

        # set up scrolled window
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.add(self.treeview)



if __name__ == '__main__':
    # test the file manager on its own
    app = Gtk.Window(title='Treeview Test')
    app.set_default_size(256, 512)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    box.pack_start(FileTree(), True, True, 0)
    app.add(box)
    app.show_all()
    Gtk.main()
