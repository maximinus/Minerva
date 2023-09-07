import gi
from enum import Enum

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


from minerva.actions import Message, message_queue, Target
from minerva.constants.misc import SearchMessage


SEARCH_MAX_HISTORY = 20


def get_search_button(filename):
    image = Gtk.Image()
    image.set_from_file(f'./gfx/search_icons/{filename}.png')
    button = Gtk.ToolButton()
    button.set_icon_widget(image)
    button.set_vexpand(False)
    button.set_hexpand(False)
    button.set_valign(Gtk.Align.CENTER)
    button.set_focus_on_click(False)
    return button


class SearchParams:
    def __init__(self, searchbar, message_type=SearchMessage.NEW_SEARCH):
        self.text = searchbar.entry.get_text()
        self.case = searchbar.match_case
        self.regex = searchbar.as_regex
        self.type = message_type


class SearchBar(Gtk.Box):
    # an overlay to handle searching for text
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL)
        self.match_case = False
        self.as_regex = False
        self.set_valign(Gtk.Align.CENTER)
        menu_button = Gtk.MenuButton()
        self.entry = Gtk.Entry()
        self.entry.set_has_frame(False)
        self.entry.get_style_context().add_class('search_entry')
        self.entry.connect('changed', self.entry_changed)
        clear_button = get_search_button('close')
        case_button = get_search_button('case')
        regex_button = get_search_button('regex')
        self.results_label = Gtk.Label(label='0 results')
        previous_button = get_search_button('previous')
        next_button = get_search_button('next')
        self.pack_start(menu_button, False, False, 0)
        self.pack_start(self.entry, False, False, 0)
        for i in [clear_button, case_button, regex_button, self.results_label, previous_button, next_button]:
            self.pack_start(i, False, False, 0)
        # connect everything
        clear_button.connect('clicked', self.clear_search)
        case_button.connect('clicked', self.set_case)
        regex_button.connect('clicked', self.set_regex)
        previous_button.connect('clicked', self.previous)
        next_button.connect('clicked', self.next)
        self.history = []

    def entry_changed(self, _widget):
        text = self.entry.get_text()
        message_queue.message(Message(Target.TEXT, 'search-text', SearchParams(self)))

    def clear_search(self, _button):
        pass

    def set_case(self, _button):
        self.match_case = not self.match_case

    def set_regex(self, _button):
        self.as_regex = not self.as_regex

    def previous(self, _button):
        # highlight and move to next match
        params = SearchParams(self, message_type=SearchMessage.PREVIOUS)
        message_queue.message(Message(Target.TEXT, 'search-text', params))

    def next(self, _button):
        # highlight and move to previous match
        params = SearchParams(self, message_type=SearchMessage.NEXT)
        message_queue.message(Message(Target.TEXT, 'search-text', params))

    def add_history(self, new_search):
        # first in last out stack
        self.history.append(new_search)
        if len(self.history) > 20:
            self.history = self.history[SEARCH_MAX_HISTORY:]

    def show_search(self):
        self.show()
        self.entry.grab_focus()

    def hide_search(self):
        self.hide()

    def update_results(self, text):
        self.results_label.set_text(text)
