import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

import json
import os.path
from pathlib import Path
from datetime import datetime

from minerva.logs import logger
from minerva.helpers import messagebox
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


# TODO for projects:
# Hide main window at start and only show when this window is closed
# Close window when new project made
# Actually make the project and store the details
# Check dir is empty on new project creation
# Load a project on double-click of existing project
# Add "no current projects" warning
# Load project when importing
# Ask when clicking close window button


class ProjectLoadException(Exception):
    pass


class ProjectDetails:
    def __init__(self, directory, name):
        self.working_folder = directory
        self.project_name = name
        self.last_update = datetime.now()
        self.image = ''

    def get_json(self):
        data = {'name': self.project_name,
                'updated': self.last_update.isoformat(),
                'image': self.image,
                'folder': str(self.working_folder)}
        return json.dumps(data)

    @staticmethod
    def from_json(data):
        try:
            project = ProjectDetails(None, data['name'])
            project.last_update = datetime.fromisoformat(data['updated'])
            project.image = data['image']
            project.working_folder = Path(data['folder'])
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


def get_all_projects():
    if not os.path.isfile(PROJECTS_LIST):
        logger.info('No projects folder found')
        return []
    try:
        with open(PROJECTS_LIST) as f:
            projects_list = json.load(f)
    except (json.JSONDecodeError, OSError) as ex:
        logger.error(f'Could not read projects list at {PROJECTS_LIST}: {ex}')
        return []
    # projects must be a list of strings
    if type(projects_list) is not list:
        logger.error(f'{PROJECTS_LIST} badly formatted: expected a list')
        return []
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
    return final_projects


def import_project(project_window):
    dialog = Gtk.FileChooserDialog(title='Select Minerva project',
                                   parent=project_window, action=Gtk.FileChooserAction.SELECT_FOLDER)
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


class NewProjectDetails:
    def __init__(self, name, directory):
        self.name = name
        self.directory = directory


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
        self.new_project = NewProjectDetails(self.name_widget.get_text(), self.dir_widget.get_filename())
        self.dialog.destroy()


class ProjectWindow:
    def __init__(self):
        self.window_builder = Gtk.Builder.new_from_file(str(PROJECTS_DIALOG))
        self.window_builder.connect_signals(self)
        self.dialog = self.window_builder.get_object('projects_window')
        self.open_button = self.window_builder.get_object('open_window')
        self.build_project_list()
        self.dialog.show_all()

    def build_project_list(self):
        projects = get_all_projects()
        if len(projects) == 0:
            self.add_empty_list()
        for i in projects:
            self.add_project(i)

    def add_empty_list(self):
        widget_builder = Gtk.Builder.new_from_file(str(PROJECTS_WIDGET))
        name = widget_builder.get_object('project_name')
        folder = widget_builder.get_object('project_folder')
        updated = widget_builder.get_object('project_date')
        name.set_text('No projects found')
        folder.set_text('')
        updated.set_text('Select from options on the right')
        new_dialog = self.widget_builder.get_object('project_list')
        self.project_list.insert(new_dialog, -1)
        # turn off "open" button
        self.open_button.set_sensitive(False)

    def add_project(self, project):
        widget_builder = Gtk.Builder.new_from_file(str(PROJECTS_WIDGET))
        project_dialog = widget_builder.get_object('project_widget')
        name = widget_builder.get_object('project_name')
        folder = widget_builder.get_object('project_folder')
        updated = widget_builder.get_object('project_date')
        name.set_text(project.project_name)
        folder.set_text(str(project.working_folder))
        updated.set_text(project.last_update.strftime('%a, %-d %b %Y'))
        box_list = self.window_builder.get_object('project_list')
        # if the box list is empty, set this one as "active"
        box_list.insert(project_dialog, -1)
        children = box_list.get_children()
        if len(children) == 1:
            # i.e. just the one we added
            box_list.select_row(children[0])

    def open_clicked(self, _data):
        print('Open')

    def new_clicked(self, __data):
        new_project_dialog = NewProjectWindow()
        new_project_dialog.run()
        if new_project_dialog.new_project is not None:
            # can close this window and display the main one
            self.dialog.destroy()
            message_queue.message(Message(Target.WINDOW, 'init-project', new_project_dialog.new_project))

    def import_clicked(self, _data):
        # get the new project
        filepath = import_project(self.dialog)
        if filepath == '':
            # nothing to do - cancelled
            return
        # import this project
        # if that worked, add it to the list of projects
        # load the project
        # close the window

    def exit_clicked(self, _data):
        # check with a messagebox
        # and then quit
        message_queue.message(Message(Target.WINDOW, 'quit-minerva'))
