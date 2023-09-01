import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk

import json
import os.path
from pathlib import Path
from datetime import datetime

from minerva.logs import logger
from minerva.helpers import messagebox, messagebox_yes_no
from minerva.actions import Message, Target, message_queue

# store details about projects
# this is stored in a file inside the given directory with the name project.json
# this contains: path to last image, last updated, project name
# later should include quicklisp setup eventually


PROJECTS_DIALOG = Path('./glade/projects.glade')
PROJECTS_WIDGET = Path('./glade/single_project.glade')
NEW_PROJECTS_DIALOG = Path('./glade/new_project.glade')
PROJECTS_LIST = Path('/home/sparky/.config/minerva/projects.json')
PROJECT_FILE_NAME = 'project.json'


class ProjectLoadException(Exception):
    pass


class ProjectDetails:
    def __init__(self, directory, name):
        self.directory = directory
        self.project_name = name
        self.last_update = datetime.now()
        self.image = ''

    def get_json(self):
        data = {'name': self.project_name,
                'updated': self.last_update.isoformat(),
                'image': self.image,
                'folder': str(self.directory)}
        return json.dumps(data)

    @staticmethod
    def from_json(data):
        try:
            project = ProjectDetails(None, data['name'])
            project.last_update = datetime.fromisoformat(data['updated'])
            project.image = data['image']
            project.directory = Path(data['folder'])
        except KeyError as ex:
            logger.error(f'Could not load project:m {ex}')
            raise ProjectLoadException(f'Missing data: {ex}')
        return project

    @staticmethod
    def load_json(filename):
        if not os.path.isfile(filename):
            raise ProjectLoadException(f'No such file {str(filename)}')
        try:
            with open(filename) as f:
                data = json.load(f)
                return ProjectDetails.from_json(data)
        except Exception as ex:
            raise ProjectLoadException(f'Could not load project :{ex}')


def get_current_projects():
    if not os.path.isfile(PROJECTS_LIST):
        logger.info('No projects folder found')
        return []
    try:
        with open(PROJECTS_LIST) as f:
            plist = json.load(f)
    except (json.JSONDecodeError, OSError) as ex:
        logger.error(f'Could not read projects list at {PROJECTS_LIST}: {ex}')
        return []
    # projects must be a list of strings
    if type(plist) is not list:
        logger.error(f'{PROJECTS_LIST} badly formatted: expected a list')
        return []
    return plist


def get_all_projects():
    projects_list = get_current_projects()
    # finally, each project must exist as a dir and the dir must contain a project.json file
    final_projects = []
    for project in projects_list:
        if not os.path.isdir(project):
            logger.error(f'Project at {project} does not exist')
            continue
        try:
            project_settings = ProjectDetails.load_json(f'{project}/{PROJECT_FILE_NAME}')
            logger.info(f'Adding project {project_settings.project_name}')
            final_projects.append(project_settings)
        except ProjectLoadException:
            continue
    # sort by date (index 0  is latest)
    final_projects.sort(key=lambda x: x.last_update, reverse=True)
    return final_projects


def add_new_project(new_project):
    projects_list = get_current_projects()
    projects_list.append(f'{str(new_project.directory)}')
    # overwrite the current list
    try:
        with open(PROJECTS_LIST, 'w') as f:
            json.dump(projects_list, f, ensure_ascii=False, indent=4)
    except OSError as ex:
        logger.error(f'Could not add project {new_project.project_name} to {PROJECT_FILE_NAME}: ex')


def import_project(project_window):
    dialog = Gtk.FileChooserDialog(title='Select Minerva project',
                                   parent=project_window, action=Gtk.FileChooserAction.OPEN)
    dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK)

    filter_project = Gtk.FileFilter()
    filter_project.set_name('Minerva project files')
    filter_project.add_pattern("project.json")
    dialog.add_filter(filter_project)

    response = dialog.run()
    if response == Gtk.ResponseType.OK:
        filename = dialog.get_filename()
    else:
        filename = ''
    dialog.destroy()
    return filename


class NewProjectWindow:
    def __init__(self):
        self.new_project_builder = Gtk.Builder.new_from_file(str(NEW_PROJECTS_DIALOG))
        self.new_project_builder.connect_signals(self)
        self.dialog = self.new_project_builder.get_object('new_project_dialog')
        self.name_widget = self.new_project_builder.get_object('name_widget')
        self.dir_widget = self.new_project_builder.get_object('dir_widget')
        self.create_button = self.new_project_builder.get_object('create_button')
        self.message_area = self.new_project_builder.get_object('message_area')
        self.create_button.set_sensitive(False)
        self.new_project = None

    def run(self):
        self.dialog.show()
        self.dialog.run()

    def check_folder_valid(self):
        # return an error message or the empty string
        folder = self.dir_widget.get_filename()
        if folder is None:
            return 'Select an empty directory'
        if not os.path.exists(folder):
            return 'Folder selection does not exist'
        if not os.path.isdir(folder):
            return 'Selection is not a directory'
        if len(os.listdir()) != 0:
            return 'Directory is not empty'
        return ''

    def name_changed(self, _widget):
        if len(self.name_widget.get_text()) == 0:
            self.message_area.set_text('Please enter a project name')
            self.create_button.set_sensitive(False)
            return
        # check folder
        message = self.check_folder_valid()
        if len(message) == 0:
            self.message_area.set_text('Press create to finish')
            self.create_button.set_sensitive(True)
        else:
            self.message_area.set_text(message)
            self.create_button.set_sensitive(False)

    def dir_chosen(self, _data):
        message = self.check_folder_valid()
        if len(message) > 0:
            self.message_area.set_text(message)
            self.create_button.set_sensitive(False)
            return
        if len(self.name_widget.get_text()) > 0:
            self.message_area.set_text('Press create to finish')
            self.create_button.set_sensitive(True)
        else:
            self.message_area.set_text('Please enter a project name')
            self.create_button.set_sensitive(False)

    def close_clicked(self, _data):
        self.dialog.destroy()

    def create_clicked(self, _data):
        print(f'Creating project {self.name_widget.get_text()} at {self.dir_widget.get_filename()}')
        self.new_project = ProjectDetails(self.dir_widget.get_filename(), self.name_widget.get_text())
        self.dialog.destroy()


class ProjectWindow:
    def __init__(self):
        self.window_builder = Gtk.Builder.new_from_file(str(PROJECTS_DIALOG))
        self.window_builder.connect_signals(self)
        self.dialog = self.window_builder.get_object('projects_window')
        self.open_button = self.window_builder.get_object('open_button')
        self.box_list = self.window_builder.get_object('project_list')
        self.box_list.set_activate_on_single_click(False)
        self.box_list.connect('row-activated', self.row_activated)
        self.box_list.connect('row-selected', self.row_selected)
        # match projects to the list
        self.projects = []
        self.build_project_list()
        self.dialog.show_all()

    def build_project_list(self):
        projects = get_all_projects()
        if len(projects) == 0:
            self.add_empty_list()
        for i in projects:
            self.add_project(i)

    def add_empty_list(self):
        # turn off "open" button
        self.open_button.set_sensitive(False)

    def add_project(self, project):
        widget_builder = Gtk.Builder.new_from_file(str(PROJECTS_WIDGET))
        project_dialog = widget_builder.get_object('project_widget')
        name = widget_builder.get_object('project_name')
        folder = widget_builder.get_object('project_folder')
        updated = widget_builder.get_object('project_date')
        name.set_text(project.project_name)
        folder.set_text(str(project.directory))
        updated.set_text(project.last_update.strftime('%a, %-d %b %Y'))
        self.box_list.insert(project_dialog, -1)
        self.projects.append(project)
        # if the box list only has 1 item, set it as "active"
        children = self.box_list.get_children()
        if len(children) == 1:
            # i.e. just the one we added
            self.box_list.select_row(children[0])

    def row_selected(self, row, _data):
        if row is None:
            self.open_button.set_sensitive(False)
        else:
            self.open_button.set_sensitive(True)

    def row_activated(self, _widget, _data):
        # get the current selection
        row = self.box_list.get_selected_row()
        project = self.projects[row.get_index()]
        self.close_dialog(project)

    def open_clicked(self, _data):
        row = self.box_list.get_selected_row()
        project = self.projects[row.get_index()]
        self.close_dialog(project)

    def new_clicked(self, __data):
        new_project_dialog = NewProjectWindow()
        new_project_dialog.run()
        if new_project_dialog.new_project is not None:
            add_new_project(new_project_dialog.new_project)
            self.close_dialog(new_project_dialog.new_project)

    def close_dialog(self, project):
        # can close this window and display the main one
        self.dialog.destroy()
        message_queue.message(Message(Target.WINDOW, 'init-project', project))

    def import_clicked(self, _data):
        # get the new project
        filepath = import_project(self.dialog)
        if filepath == '':
            # nothing to do - cancelled
            return
        # import this project
        # this means adding it to the list of projects
        try:
            imported_project = ProjectDetails.load_json(filepath)
        except ProjectLoadException:
            messagebox(self.dialog, 'Bad json: Could not load file', icon=Gtk.MessageType.ERROR)
            return
        add_new_project(imported_project)
        if messagebox_yes_no(self.dialog, 'Load project now?') is True:
            self.close_dialog(imported_project)
        # no, just add the project
        self.add_project(imported_project)

    def exit_clicked(self, _data):
        # check with a messagebox
        # and then quit
        message_queue.message(Message(Target.WINDOW, 'quit-minerva'))
