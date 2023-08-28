import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

import json
import os.path
from pathlib import Path
from datetime import datetime

from minerva.logs import logger

# store details about projects
# this is stored in a file inside the given directory with the name project.json
# this contains: path to last image, last updated, project name
# later should include quicklisp setup eventually


PROJECTS_DIALOG = Path('./glade/projects.glade')
PROJECTS_WIDGET = Path('./glade/single_project.glade')
PROJECTS_LIST = Path('/home/sparky/.config/minerva/projects.json')
PROJECT_FILE_NAME = 'project.json'


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
            project.last_update = data['updated']
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


class ProjectWindow:
    def __init__(self):
        # closed by the window itself
        self.window_builder = Gtk.Builder.new_from_file(str(PROJECTS_DIALOG))
        self.window_builder.connect_signals(self)
        self.dialog = self.window_builder.get_object('projects_window')
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
        #name.set_text('No projects found')
        #folder.set_text('')
        #updated.set_text('Select from options on the right')
        #new_dialog = self.widget_builder.get_object('project_widget')
        #self.project_list.insert(new_dialog, -1)

    def add_project(self, project):
        widget_builder = Gtk.Builder.new_from_file(str(PROJECTS_WIDGET))
        project_dialog = widget_builder.get_object('project_widget')
        name = project_dialog.get_template_child(Gtk.Label, 'project_name')
        folder = project_dialog.get_template_child(Gtk.Label, 'project_folder')
        updated = project_dialog.get_template_child(Gtk.Label, 'project_date')
        name.set_text(project.project_name)
        folder.set_text(str(project.working_folder))
        updated.set_text(project.last_update.strftime('%a, %-d %b %Y'))
        new_dialog = self.dialog.get_template_child(Gtk.ListBox, 'project_list')
        project_dialog.insert(new_dialog, -1)
