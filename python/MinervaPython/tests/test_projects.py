from pathlib import Path
from datetime import datetime
from unittest import TestCase

from minerva.projects import ProjectDetails, ProjectLoadException


class TestProject(TestCase):
    def test_get_json(self):
        project = ProjectDetails(Path('.'), 'test')
        json = project.get_json()
        for key in ['name', 'updated', 'image', 'folder']:
            self.assertTrue(key in json)

    def test_load_from_json(self):
        example = {'name': 'test',
                   'updated': datetime.now().isoformat(),
                   'image': str(Path(__file__)),
                   'folder': str(Path(__file__).parent)}
        project = ProjectDetails.from_json('', example)
        self.assertEqual(project.project_name, 'test')

    def test_fails_with_missing_json(self):
        example = {'name': 'test'}
        with self.assertRaises(ProjectLoadException):
            ProjectDetails.from_json('', example)

    def test_date_loaded_accuractly(self):
        time_now = datetime.now()
        example = {'name': 'test',
                   'updated': time_now.isoformat(),
                   'image': str(Path(__file__)),
                   'folder': str(Path(__file__).parent)}
        project = ProjectDetails.from_json('', example)
        recorded_time = datetime.fromisoformat(project.last_update)
        self.assertEqual(time_now, recorded_time)
