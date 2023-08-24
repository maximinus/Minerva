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


    def get_files(self):
        directory = Path(__file__).parent
        for filename in os.listdir(directory):
            size = os.path.getsize(os.path.join(directory, filename))
            # the second element is displayed in the second TreeView column
            # but that column is sorted by the third element
            # so the file sizes are sorted as numbers, not as strings
            self.file_store.append([filename, f'{size}', size])
