import os

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

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

        renderer_1 = Gtk.CellRendererText()
        column_1 = Gtk.TreeViewColumn('File Name', renderer_1, text=0)
        # Calling set_sort_column_id makes the treeViewColumn sortable
        # by clicking on its header. The column is sorted by
        # the ListStore column index passed to it
        # (in this case 0 - the first ListStore column)
        column_1.set_sort_column_id(0)
        self.file_tree.append_column(column_1)

        # xalign=1 right-aligns the file sizes in the second column
        renderer_2 = Gtk.CellRendererText(xalign=1)
        # text=1 pulls the data from the second ListStore column
        # which contains filesizes in bytes formatted as strings
        # with thousand separators
        column_2 = Gtk.TreeViewColumn('Size in bytes', renderer_2, text=1)
        # Mak the Treeview column sortable by the third ListStore column
        # which contains the actual file sizes
        column_2.set_sort_column_id(2)
        self.file_tree.append_column(column_2)

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


class FileTree(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()
        self.store = Gtk.TreeStore(str)
        self.treeview = Gtk.TreeView(model=self.store)
        renderer_1 = Gtk.CellRendererText()
        column_1 = Gtk.TreeViewColumn('Filename', renderer_1, text=0)
        self.treeview.append_column(column_1)
        # do the calculation at the end
        get_tree_view(self.store, None, None)

        # set up scrolled window
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.add(self.treeview)


def get_tree_view(store, row, new_dir):
    if new_dir is None:
        new_dir = DirectoryTree(Path(__file__).parent.parent)
    for next_dir in new_dir.directories:
        if row is None:
            new_row = store.append(None, [next_dir.dir_path])
        else:
            new_row = store.append(row, [next_dir.dir_path])
        get_tree_view(store, new_row, next_dir)

    for file in new_dir.files:
        store.append(row, [file])


if __name__ == '__main__':
    # test the file manager on its own
    app = Gtk.Window(title='Treeview Test')
    app.set_default_size(256, 512)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    box.pack_start(FileTree(), True, True, 0)
    app.add(box)
    app.show_all()
    Gtk.main()