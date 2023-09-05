import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


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

"""
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
"""


class SearchBar(Gtk.Box):
    # an overlay to handle searching for text
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL)
        self.match_case = False
        self.as_regex = False
        menu_button = Gtk.MenuButton()
        entry = Gtk.Entry()
        clear_button = Gtk.Button.new_with_label('x')
        case_button = Gtk.Button.new_with_label('Aa')
        regex_button = Gtk.Button.new_with_label('.*')
        results_label = Gtk.Label(label='0 results')
        previous_button = Gtk.Button.new_with_label('<')
        next_button = Gtk.Button.new_with_label('>')
        self.pack_start(menu_button, False, False, 0)
        self.pack_start(entry, False, False, 0)
        for i in [clear_button, case_button, regex_button, results_label, previous_button, next_button]:
            self.pack_start(i, False, False, 0)
        # connect everything
        clear_button.connect('clicked', self.clear_search)
        case_button.connect('clicked', self.set_case)
        regex_button.connect('clicked', self.set_regex)
        previous_button.connect('clicked', self.previous)
        next_button.connect('clicked', self.next)

    def clear_search(self, _button):
        pass

    def set_case(self, _button):
        self.match_case = not self.match_case

    def set_regex(self, _button):
        self.as_regex = not self.as_regex

    def previous(self, _button):
        # highlight and move to next match
        pass

    def next(self, _button):
        # highlight and move to previous match
        pass

    def close(self, _button, _data):
        pass
