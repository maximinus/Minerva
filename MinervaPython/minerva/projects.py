import json
import os.path
from pathlib import Path
from datetime import datetime

from minerva.logs import logger

# store details about projects
# this is stored in a file inside the given directory with the name project.json
# this contains: path to last image, last updated, project name
# later should include quicklisp setup eventually


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
    def from_json(self, data):
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
    def load_json(self, filename):
        if not os.path.isfile(filename):
            raise ProjectLoadException(f'No such file {str(filename)}')
        try:
            with open(filename) as f:
                return json.load(f)
        except Exception as ex:
            raise ProjectLoadException(f'Could not load project :{ex}')
