import json
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
        self.image = None

    def get_json(self):
        pass

    @staticmethod
    def load_from_json(self, filename):
        try:
            with open(filename) as f:
                data = json.load(f)
            project = ProjectDetails(None, data['name'])
            project.last_update = data['updated']
            project.image = data['image']
            project.working_folder = Path(data['folder'])
        except Exception as ex:
            logger.error(f'Could not load project:m {ex}')
            raise ProjectLoadException
        return project
