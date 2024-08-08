import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk

from enum import Enum

# these are constants in Gdk: see https://docs.gtk.org/gdk3/index.html
DIGIT_KEYS = [Gdk.KEY_0, Gdk.KEY_1, Gdk.KEY_2, Gdk.KEY_3, Gdk.KEY_4,
              Gdk.KEY_5, Gdk.KEY_6, Gdk.KEY_7, Gdk.KEY_8, Gdk.KEY_9]

class Keys(Enum):
    RETURN = 65293
    CURSOR_UP = 65362
    CURSOR_DOWN = 65364
    CURSOR_LEFT = 65361
    CURSOR_RIGHT = 65363
    BACKSPACE = 65288
    DELETE = 65535
    HOME = 65360
    END = 65367
    ESCAPE = 65307


def is_key_digit(key):
    return key in DIGIT_KEYS


def get_digit_value(key):
    if not is_key_digit(key):
        return -1
    return DIGIT_KEYS.index(key)
