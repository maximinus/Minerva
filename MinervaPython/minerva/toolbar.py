import gi
import json

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


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
