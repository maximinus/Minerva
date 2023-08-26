import os

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GdkPixbuf

from pathlib import Path


class MinvTree(Gtk.Notebook):
    def __init__(self):
        super().__init__()
        self.set_tab_pos(Gtk.PositionType.LEFT)
        self.set_scrollable(False)
        self.set_tab_reordable(False)
        # to this panel we add 2 trees
        self.lisp_tree = Gtk.TreeView()
        self.file_tree = Gtk.TreeView()
        self.file_store = Gtk.ListStore(str, str, int)
        self.get_files()

        renderer0 = Gtk.CellRendererPixbuf()
        column0 = Gtk.TreeViewColumn('', renderer0)
        renderer1 = Gtk.CellRendererText()
        column1 = Gtk.TreeViewColumn('File Name', renderer1, text=0)

        self.file_tree.append_column(column0)
        self.file_tree.append_column(column1)

        # Use ScrolledWindow to make the TreeView scrollable
        # Otherwise the TreeView would expand to show all items
        # Only allow vertical scrollbar
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled_window.add(self.file_tree)
        scrolled_window.set_min_content_height(200)

        self.add(scrolled_window)
        self.show_all()


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


class FileTree(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()
        # design the columns and add them
        column = Gtk.TreeViewColumn('Filename')
        cell_text = Gtk.CellRendererText()
        cell_image = Gtk.CellRendererPixbuf()

        column.pack_start(cell_image, False)
        column.pack_start(cell_text, False)
        column.add_attribute(cell_image, 'pixbuf', 0)
        column.add_attribute(cell_text, 'text', 1)

        self.store = Gtk.TreeStore(GdkPixbuf.Pixbuf, str)
        self.treeview = Gtk.TreeView(self.store)
        self.treeview.append_column(column)

        # do the calculation at the end
        get_tree_view(self.store, None, None, get_file_icons())

        # set up scrolled window
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.add(self.treeview)


def get_tree_view(store, row, new_dir, images):
    if new_dir is None:
        new_dir = DirectoryTree(Path(__file__).parent.parent)
    for next_dir in new_dir.directories:
        if row is None:
            new_row = store.append(None, [images[0], next_dir.dir_path])
        else:
            new_row = store.append(row, [images[0], next_dir.dir_path])
        get_tree_view(store, new_row, next_dir, images)

    for file in new_dir.files:
        store.append(row, [images[1], file])


if __name__ == '__main__':
    # test the file manager on its own
    app = Gtk.Window(title='Treeview Test')
    app.set_default_size(256, 512)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    box.pack_start(FileTree(), True, True, 0)
    app.add(box)
    app.show_all()
    Gtk.main()
