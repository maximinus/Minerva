import gi
import json

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


def get_menu_from_config(accel_group, action_router):
    # get our own menubar
    with open("./data/menus.json", "r") as read_file:
        menu_data = json.load(read_file)
    menu_bar = Gtk.MenuBar()
    for menu_item in menu_data:
        new_menu = Gtk.Menu()
        menu_top = Gtk.MenuItem(menu_item['text'])
        menu_top.set_submenu(new_menu)
        for menu_choice in menu_item['items']:
            if menu_choice['text'] == '-':
                new_menu.append(Gtk.SeparatorMenuItem())
                continue
            else:
                if 'icon' in menu_choice:
                    menu_item = Gtk.ImageMenuItem(label=menu_choice['text'])
                    image = Gtk.Image()
                    image.set_from_file(f'./gfx/icons/{menu_choice["icon"]}.png')
                    menu_item.set_image(image)
                else:
                    menu_item = Gtk.MenuItem(label=menu_choice['text'])
                if 'shortcut' in menu_choice:
                    key, mod = Gtk.accelerator_parse(menu_choice['shortcut'])
                    menu_item.add_accelerator('activate', accel_group, key, mod, Gtk.AccelFlags.VISIBLE)
                if 'action' in menu_choice:
                    if 'data' in menu_choice:
                        menu_item.connect('activate', action_router, menu_choice['action'], menu_choice['data'])
                    else:
                        menu_item.connect('activate', action_router, menu_choice['action'])
                else:
                    menu_item.connect('activate', action_router, 'messagebox', 'Not yet coded')
                new_menu.append(menu_item)
        menu_bar.append(menu_top)
    return menu_bar
