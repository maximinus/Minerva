from unittest import TestCase

from minerva.preferences import Config


class TestConfig(TestCase):
    def test_default_is_valid(self):
        config = Config()
        self.assertTrue(config.valid)

    def test_values(self):
        config = Config()
        self.assertIsNotNone(config.editor_font)
        self.assertIsNotNone(config.repl_font)
        self.assertIsNotNone(config.lisp_binary)
