import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


SEARCH_MAX_HISTORY = 20


def get_search_button(filename):
    toolbar = Gtk.Toolbar()
    image = Gtk.Image()
    image.set_from_file(f'./gfx/search_icons/{filename}.png')
    button = Gtk.ToolButton()
    button.set_icon_widget(image)
    button.set_vexpand(False)
    button.set_hexpand(False)
    button.set_valign(Gtk.Align.CENTER)
    #button.set_relief(Gtk.ReliefStyle.NONE)
    button.set_focus_on_click(False)
    return button


class SearchBar(Gtk.Box):
    # an overlay to handle searching for text
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL)
        self.match_case = False
        self.as_regex = False
        self.set_valign(Gtk.Align.CENTER)
        menu_button = Gtk.MenuButton()
        entry = Gtk.Entry()
        entry.set_has_frame(False)
        entry.get_style_context().add_class('search_entry')
        clear_button = get_search_button('close')
        case_button = get_search_button('case')
        regex_button = get_search_button('regex')
        results_label = Gtk.Label(label='0 results')
        previous_button = get_search_button('previous')
        next_button = get_search_button('next')
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
        self.history = []

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

    def add_history(self, new_search):
        # first in last out stack
        self.history.append(new_search)
        if len(self.history) > 20:
            self.history = self.history[SEARCH_MAX_HISTORY:]
