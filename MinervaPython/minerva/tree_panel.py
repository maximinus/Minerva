import os

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GdkPixbuf

from pathlib import Path


class DirectoryTree:
    def __init__(self, directory):
        self.dir_path = directory.name
        self.directories = []
        self.files = []
        self.get_directory(directory)

    def get_directory(self, directory):
        for filename in os.listdir(directory):
            fullpath = directory / filename
            if os.path.isdir(fullpath):
                self.directories.append(DirectoryTree(fullpath))
            else:
                self.files.append(fullpath.name)


def get_file_icons():
    root = Path(__file__).parent.parent / 'gfx' / 'file_icons'
    return [GdkPixbuf.Pixbuf.new_from_file(str(root / f'{x}.png')) for x in ['folder', 'lisp', 'text']]


def get_tree_view(store, row, new_dir, images):
    if new_dir is None:
        new_dir = DirectoryTree(Path(__file__).parent.parent)
    for next_dir in new_dir.directories:
        sort_value = f'd_{next_dir.dir_path.lower()}'
        if row is None:
            new_row = store.append(None, [images[0], next_dir.dir_path, sort_value])
        else:
            new_row = store.append(row, [images[0], next_dir.dir_path, sort_value])
        get_tree_view(store, new_row, next_dir, images)

    for file in new_dir.files:
        sort_value = f'f_{file.lower()}'
        if file.endswith('lisp'):
            store.append(row, [images[1], file, sort_value])
        else:
            store.append(row, [images[2], file, sort_value])


def file_sort(model, row1, row2, _user_data):
    # we look at the 3rd column of each row
    # directories start with D_ and files F_; directories come first
    value1 = model.get_value(row1, 2).lower()
    value2 = model.get_value(row2, 2).lower()
    if value1 < value2:
        return -1
    return 1


class FileTree(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()
        # last column is used for sorting
        self.store = Gtk.TreeStore(GdkPixbuf.Pixbuf, str, str)

        # design the columns and add them
        column = Gtk.TreeViewColumn('Filename')
        cell_text = Gtk.CellRendererText()
        cell_image = Gtk.CellRendererPixbuf()

        column.pack_start(cell_image, False)
        column.pack_start(cell_text, False)
        column.add_attribute(cell_image, 'pixbuf', 0)
        column.add_attribute(cell_text, 'text', 1)

        self.store.set_sort_column_id(0, Gtk.SortType.ASCENDING)
        self.store.set_sort_func(0, file_sort, None)

        self.treeview = Gtk.TreeView(model=self.store)
        self.treeview.append_column(column)

        # do the calculation at the end
        get_tree_view(self.store, None, None, get_file_icons())

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
