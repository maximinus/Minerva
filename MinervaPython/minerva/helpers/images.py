import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

import os.path
from pathlib import Path

from minerva.logs import logger


# helper functions to load images

# TODO: Load from Minerva config
GFX_FOLDER = Path(__file__).parent.parent.parent / 'gfx'
ERROR_IMAGE = GFX_FOLDER / 'error.png'


def get_image(filename):
    # filename is added to root/gfx
    image_filepath = GFX_FOLDER / filename
    if not os.path.exists(image_filepath):
        logger.error(f'Could not find image {image_filepath}')
        image_filepath = ERROR_IMAGE
    image = Gtk.Image()
    image.set_from_file(image_filepath)
    return image
