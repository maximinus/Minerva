import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango, Gdk

from pathlib import Path

from minerva.logs import logger
from minerva.preferences import config
from minerva.constants.keycodes import Keys
from minerva.constants.misc import SearchMessage
from minerva.helpers.messagebox import messagebox_yes_no
from minerva.actions import message_queue, Target, Message


COLOR_RED = '#FF8888'
COLOR_BLUE = '#8888FF'

NOTEBOOK_LABEL_MARGIN = 2


# TODO: Text search
# when text is searched, the following happens:
# all matches are highlighted in orange, and the first selection is selected (and not yellow)
# The selection is the first match that is in front of the cursor
# Clicking next or previous will move the selection forward or back
# If the text is changed, search begins again
# If escape or close is clicked, everything is cleared
# if case is selected / deselected, the search is started again
# If a new page is selected and search is active, the search is done on the new page

class IterPair:
    # store a pair of Gtk.TextIters for each match
    def __init__(self, start, end):
        self.start = start
        self.end = end


class SearchResults:
    # store the results
    def __init__(self, matches, index=0):
        self.matches = matches
        self.index = index

    def add_match(self, single_match):
        self.matches.append(single_match)

    @property
    def empty(self):
        return len(self.matches) == 0

    def get_current_selection(self):
        return self.matches[self.index]

    def increment(self):
        if self.index + 1 < len(self.matches):
            self.index += 1

    def decrement(self):
        if self.index > 0:
            self.index -= 1


def get_name_label(html_text, color=None):
    # return a label with markup
    label = Gtk.Label()
    if color is None:
        label.set_markup(html_text)
    else:
        label.set_markup(f'<span color="{color}">{html_text}</span>')
    return label


class TextOverlay(Gtk.Window):
    # an overlay to put over the text showing predictive text
    def __init__(self, parent):
        super().__init__(Gtk.WindowType.POPUP)
        self.set_visible(False)
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_transient_for(parent)
        self.set_resizable(False)
        geo_hints = Gdk.Geometry()
        geo_hints.min_width = 0
        geo_hints.min_height = 0
        self.set_geometry_hints(None, geo_hints, Gdk.WindowHints.MIN_SIZE)
        self.set_halign(Gtk.Align.START)
        self.set_valign(Gtk.Align.START)
        self.lines = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.lines.set_orientation(orientation=Gtk.Orientation.VERTICAL)
        self.lines.set_halign(Gtk.Align.START)
        self.lines.set_valign(Gtk.Align.START)
        self.lines.get_style_context().add_class('code_hint_box')
        # add the example lines
        self.add_single_line('defclass name (super) (slot) options', selected=True)
        self.add_single_line('defmacro name (args ...) form')
        self.add_single_line('defun name (args ...)')
        self.add(self.lines)

    def add_single_line(self, text, selected=False):
        new_label = Gtk.Label()
        new_label.set_markup(f'<span font_desc="Mono Normal 10">{text}</span>')
        new_label.set_halign(Gtk.Align.FILL)
        new_label.set_valign(Gtk.Align.START)
        new_label.set_xalign(0.0)
        if selected:
            new_label.get_style_context().add_class('autocomplete_selected')
        else:
            new_label.get_style_context().add_class('autocomplete_not_selected')
        self.lines.pack_start(new_label, False, False, 0)


def get_filename(self, window):
    dialog = Gtk.FileChooserDialog(title="Select file", parent=window, action=Gtk.FileChooserAction.SAVE)
    dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_SAVE, Gtk.ResponseType.OK)
    dialog.set_do_overwrite_confirmation(True)
    response = dialog.run()
    if response == Gtk.ResponseType.OK:
        filename = Path(dialog.get_filename())
    else:
        filename = None
    dialog.destroy()
    return filename


class SingleTextView(Gtk.ScrolledWindow):
    # Single file of text to be edited
    window_decoration_height = 0

    def __init__(self, code_overlay, font=None, text=None, filename=None):
        super().__init__()
        self.set_hexpand(True)
        self.set_vexpand(True)
        self.text = Gtk.TextView()
        self.buffer = self.text.get_buffer()
        if font is None:
            Pango.FontDescription(config.get('editor_font'))
        else:
            self.text.override_font(Pango.FontDescription(font))
        if text is None:
            self.buffer.set_text('')
        else:
            self.buffer.set_text(text)
        self.add(self.text)
        self.code_overlay = code_overlay
        self.filename = filename
        self.search_results = None
        # if we have a filename then we are saved
        self.saved = filename is not None
        self.text.connect('focus-in-event', self.gained_focus)
        self.text.connect('focus-out-event', self.lost_focus)
        self.text.connect('key-press-event', self.key_press)
        self.buffer.connect('changed', self.text_changed)
        self.buffer.connect('notify::cursor-position', self.cursor_moved)
        # the tag applied if there is a match for the search or replace
        self.search_tag = self.buffer.create_tag('orange_background', background='orange')

    def text_changed(self, _widget):
        logger.info('Text changed')

    def key_press(self, _widget, event):
        # enter key pressed?
        if event.keyval == Keys.RETURN.value:
            logger.info('Enter pressed')

    def gained_focus(self, _event, _data):
        #self.set_code_hint_window()
        pass

    def lost_focus(self, _event, _data):
        # always hide the code hint window
        self.code_overlay.hide()

    def cursor_moved(self, _buffer, _params):
        # ideally we want to let the event handle itself and THEN update the window
        self.set_code_hint_window()

    def set_code_hint_window(self):
        # update window decoration offset if not computed
        if self.window_decoration_height == 0:
            gdk_window = self.text.get_window(Gtk.TextWindowType.WIDGET)
            s1 = gdk_window.get_frame_extents().height
            s2 = self.text.get_toplevel().get_allocation().height
            self.window_decoration_height = s1 - s2
        window_pos = self.get_window_position()
        self.code_overlay.move(window_pos[0], window_pos[1])
        #self.code_overlay.show_all()

    def get_window_position(self):
        # return the position the code hint window should be in
        root = self.text.get_toplevel()
        win_pos = root.get_position()
        widget_pos = self.text.translate_coordinates(root, 0, 0)
        # [0] is for the strong cursor
        cursor = self.text.get_cursor_locations(None)[0]
        # we always want the window to be over the line below what we are typing
        pos = self.text.buffer_to_window_coords(Gtk.TextWindowType.TEXT, cursor.x, cursor.y)
        # add window position + cursor position + cursor height
        height = win_pos[1] + widget_pos[1] + pos[1] + self.window_decoration_height + cursor.height
        return [win_pos[0] + widget_pos[0] + pos[0], height]

    def get_label(self):
        # this is actually a box
        # on the left, a text view of the file
        # on the right, an icon to close the window
        head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)

        # get the components
        if self.filename is None:
            display_name = 'empty'
        else:
            display_name = self.filename.name
        if self.saved:
            name_label = get_name_label(display_name, COLOR_BLUE)
        else:
            name_label = get_name_label(f'<i>{display_name}</i>', COLOR_RED)
        name_label.set_margin_right(NOTEBOOK_LABEL_MARGIN)
        name_label.set_xalign(0.0)
        name_label.set_yalign(0.4)

        image = Gtk.Image()
        image.set_from_file(f'./gfx/icons/close_tiny.png')
        button = Gtk.Button()
        button.set_image(image)
        button.set_alignment(1.0, 0.5)
        button.set_relief(Gtk.ReliefStyle.NONE)
        button.set_focus_on_click(False)
        button.connect('clicked', self.close_button_clicked)

        head.pack_start(name_label, False, False, 0)
        head.pack_start(button, False, False, 0)
        head.show_all()
        return head

    def close_button_clicked(self, button):
        # send a message to close the buffer
        message_queue.message(Message(Target.TEXT, 'close_buffer', self))

    def save_file(self, window):
        # if the filename exists, just save it there
        if self.filename is not None:
            filename = self.filename
        else:
            filename = self.get_filename(window)
            if filename is None:
                # no filename selected
                return
        with open(filename, 'w') as file:
            buffer = self.text.get_buffer()
            start = buffer.get_start_iter()
            end = buffer.get_end_iter()
            file.write(buffer.get_text(start, end, True))
        if self.filename is None:
            self.filename = filename
        logger.info(f'Saved file to {filename}')
        self.saved = True

    def close(self):
        # call before we remove this buffer
        # return True if we want to close
        if self.saved is True:
            # nothing to do, and save is ok
            return True
        # get parent window
        parent = self.text.get_toplevel()
        # if we are saved and not modified, no need to ask
        if self.filename is None:
            # Nothing has been defined
            if messagebox_yes_no(parent, 'Save empty buffer?') is False:
                return True
            # save as expected, if cancelled then return False
            self.save_file(parent)
            if self.saved:
                return True
            return False
        if self.saved is False:
            # have filename but not saved
            path_file = Path(self.filename)
            if messagebox_yes_no(parent, f'Save to {path_file.name}?') is True:
                self.save_file(parent)
            return True

    def update_font(self, new_font):
        self.text.override_font(Pango.FontDescription(new_font))

    def search_text(self, search_params):
        match search_params.type:
            case SearchMessage.NEW_SEARCH:
                self.new_search(search_params)
            case SearchMessage.NEXT:
                self.search_next()
            case SearchMessage.PREVIOUS:
                self.search_previous()
            case SearchMessage.CLOSE:
                self.search_close()
            case _:
                logger.error(f'Did not understand search message {search_params.message_type}')

    def new_search(self, search_params):
        # we need to do a search in the TextView
        # clear the old search
        start_iter = self.buffer.get_start_iter()
        # keep searching until no more are found
        still_searching = True
        self.search_results = SearchResults([])
        search_type = Gtk.TextSearchFlags.CASE_INSENSITIVE if search_params.case else None
        while still_searching:
            found = start_iter.forward_search(search_params.text, 0, search_type)
            if found:
                start, end = found
                self.search_results.add_match(IterPair(start, end))
                start_iter = end
            else:
                still_searching = False
        # get the total results
        if self.search_results.empty:
            # nothing to do
            self.buffer.remove_all_tags(self.buffer.get_start_iter(), self.buffer.get_end_iter())
            message_queue.message(Message(Target.TOOLBAR, 'update-search', '0 results'))
            return
        self.update_search_tags()

    def update_search_tags(self):
        self.buffer.remove_all_tags(self.buffer.get_start_iter(), self.buffer.get_end_iter())
        for index, i in enumerate(self.search_results.matches):
            if index != self.search_results.index:
                self.buffer.apply_tag(self.search_tag, i.start, i.end)
            else:
                self.buffer.select_range(i.start, i.end)
        results = len(self.search_results.matches)
        if results == 1:
            message_queue.message(Message(Target.TOOLBAR, 'update-search', '1 result'))
        else:
            message_queue.message(Message(Target.TOOLBAR, 'update-search', f'{results} results'))

    def search_next(self):
        if self.search_results is None:
            return
        self.search_results.increment()
        self.update_search_tags()

    def search_previous(self):
        if self.search_results is None:
            return
        self.search_results.decrement()
        self.update_search_tags()

    def search_close(self):
        pass


class TextEdit(Gtk.Notebook):
    def __init__(self, window, search):
        # notebook to handle all code for text files and move out of main.py
        super().__init__()
        self.code_hint_overlay = TextOverlay(window)
        self.searchbar = search

        # create a single page
        new_view = SingleTextView(self.code_hint_overlay)
        self.append_page(new_view, new_view.get_label())
        self.connect('switch_page', self.switch_page)

    def switch_page(self, _notebook, _page, page_num):
        # TODO: Apply search terms if search exists
        print('Page switched')

    def new_file(self):
        # add an empty notebook
        new_view = SingleTextView(self.code_hint_overlay)
        self.append_page(new_view, new_view.get_label())
        self.show_all()
        self.set_current_page(-1)

    def get_current_textview(self):
        index = self.get_current_page()
        if index < 0:
            # no current page
            return
        return self.get_nth_page(index).text

    def save_file(self):
        text_view = self.get_current_textview()
        if text_view is None:
            return
        text_view.save_file(self)
        # we likely need to update the name on the tab
        page = self.get_nth_page(self.get_current_page())
        self.set_tab_label(page, text_view.get_label())

    def load_file(self):
        dialog = Gtk.FileChooserDialog(title="Select file", parent=self.get_toplevel(), action=Gtk.FileChooserAction.OPEN)
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK)

        filter_lisp = Gtk.FileFilter()
        filter_lisp.set_name('Lisp files')
        filter_lisp.add_pattern('*.lisp')
        dialog.add_filter(filter_lisp)

        filter_txt = Gtk.FileFilter()
        filter_txt.set_name('Text files')
        filter_txt.add_pattern('*.txt')
        dialog.add_filter(filter_txt)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            filename = Path(dialog.get_filename())

            # TODO: if we already have that file, just go to the tab
            #index = 0
            #for i in self.buffers.buffer_list:
            #    if i.filename == filename:
            #        self.set_current_page(index)
            #        dialog.destroy()
            #        return
            #    index += 1

            # load the file and add to the textview
            with open(filename) as f:
                text = ''.join(f.readlines())
            new_view = SingleTextView(self.code_hint_overlay, filename=filename, text=text)
            self.append_page(new_view, new_view.get_label())

            # switch to the new page one. Must display before switching
            self.show_all()
            self.set_current_page(-1)
            logger.info(f'Loaded file from {filename}')
        dialog.destroy()

    def close_notebook(self, index):
        # remove the notebook on this index
        # no need to worry about the data by this point
        self.remove_page(index)

    def show_search(self):
        self.searchbar.show_search()

    def update_font(self, font_data):
        for text_view in self.get_children():
            text_view.update_font(font_data)

    def search_text(self, search_params):
        # pass this on to the current textview
        index = self.get_current_page()
        if index >= 0:
            self.get_nth_page(index).search_text(search_params)

    def message(self, message):
        match message.action:
            case 'close-notebook':
                self.close_notebook(message.data)
            case 'new-file':
                self.new_file()
            case 'load-file':
                self.load_file()
            case 'save-file':
                self.save_file()
            case 'update_font':
                self.update_font(message.data)
            case 'close_buffer':
                self.close_buffer(message.data)
            case 'show-search':
                self.show_search()
            case 'search-text':
                self.search_text(message.data)
            case 'replace-text':
                pass
            case _:
                logger.error(f'Text cannot understand action {message.action}')
