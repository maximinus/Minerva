import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


# some simple helper functions


def messagebox(parent, message, icon=Gtk.MessageType.INFO):
    dialog = Gtk.MessageDialog(
        transient_for=parent, flags=0, message_type=icon, buttons=Gtk.ButtonsType.OK, text=message)
    dialog.run()
    dialog.destroy()


def messagebox_yes_no(parent, question):
    # returns True if user selected Yes
    dialog = Gtk.MessageDialog(transient_for=parent, flags=0, message_type=Gtk.MessageType.QUESTION,
                               buttons=Gtk.ButtonsType.YES_NO, text=question)
    response = dialog.run()
    dialog.destroy()
    return response == Gtk.ResponseType.YES
