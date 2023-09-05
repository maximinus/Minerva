from enum import Enum

# these are constants in Gdk: see https://docs.gtk.org/gdk3/index.html

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
