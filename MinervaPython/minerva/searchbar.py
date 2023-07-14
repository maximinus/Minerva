import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk

# search widget
# drop down menu
# the search box
# the type of search (regex, case)
# next and back
# close search widget on the right hand side

SEARCHBAR_PADDING = 0


def get_search_button(filename):
    button = Gtk.Button()
    image = Gtk.Image()
    image.set_from_file(f'./gfx/icons/{filename}.png')
    button.set_image(image)
    button.set_vexpand(False)
    button.set_hexpand(False)
    button.set_valign(Gtk.Align.CENTER)
    button.set_relief(Gtk.ReliefStyle.NONE)
    button.set_focus_on_click(False)
    return button


class SearchBar:
    def __init__(self, toolbar):
        self.box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)

        self.search = Gtk.SearchEntry()
        self.search.set_vexpand(False)
        self.search.margin = 0
        self.search.set_valign(Gtk.Align.CENTER)

        self.button_case = get_search_button('search_case')
        self.button_regex = get_search_button('search_regex')
        self.button_forward = get_search_button('search_next')
        self.button_back = get_search_button('search_previous')

        self.box.pack_start(toolbar, False, False, 0)
        for button in [self.button_case, self.button_regex, self.button_forward, self.button_back]:
            self.box.pack_end(button, False, False, SEARCHBAR_PADDING)
        self.box.pack_end(self.search, False, False, 0)