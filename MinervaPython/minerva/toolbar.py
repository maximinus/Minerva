import gi
import json

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from minerva.logs import logger
from minerva.searchbar import SearchBar


def get_toolbar_from_config(action_router):
    with open("./data/toolbar.json", "r") as read_file:
        toolbar_data = json.load(read_file)
    toolbar = Gtk.Toolbar()
    for tool in toolbar_data:
        image = Gtk.Image()
        image.set_from_file(f'./gfx/icons/{tool["icon"]}.png')
        tool_item = Gtk.ToolButton()
        tool_item.set_icon_widget(image)
        if 'tooltip' in tool:
            tool_item.set_tooltip_text(tool["tooltip"])
        if 'action' in tool:
            if 'data' in tool:
                tool_item.connect('clicked', action_router, tool['action'])
            else:
                tool_item.connect('clicked', action_router, tool['action'])
        else:
            tool_item.connect('clicked', action_router, 'messagebox', 'Not yet coded')
        # -1 means append to the end of the toolbar
        toolbar.insert(tool_item, -1)
    return toolbar


class Toolbar(Gtk.Box):
    def __init__(self, action_router):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_toolbar = get_toolbar_from_config(action_router)
        self.search_toolbar = SearchBar()
        self.pack_start(self.main_toolbar, False, False, 0)
        self.pack_end(self.search_toolbar, False, False, 0)

    def message(self, message):
        match message.action:
            case 'update-search':
                self.search_toolbar.update_results(message.data)
                self.close_notebook(message.data)
            case _:
                logger.error(f'Toolbar cannot understand action {message.action}')
