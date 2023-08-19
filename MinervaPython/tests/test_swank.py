import os.path
from unittest import TestCase
from pathlib import Path

from minerva.swank import SwankMessage, LispRuntime


class TestMessage(TestCase):
    def test_simple_parse(self):
        sent = '(:return (:ok ("(+ &rest ===> numbers <===)" t)) 8)'
        message = SwankMessage(sent)
        self.assertEqual(len(message.ast), 3)

    def test_simple_parse_message_type(self):
        sent = '(:return (:ok ("(+ &rest ===> numbers <===)" t)) 8)'
        message = SwankMessage(sent)
        self.assertEqual(str(message.message_type), ':return')

    def test_simple_parse_second_element(self):
        sent = '(:return (:ok ("(+ &rest ===> numbers <===)" t)) 8)'
        message = SwankMessage(sent)
        self.assertEqual(message.ast[2], 8)


def get_swank_dir():
    # return based on this file in ./tests
    filepath = Path(__file__).parent.parent
    return filepath


class TestLispBinary(TestCase):
    swank_path = get_swank_dir()
    lisp_path = '/usr/bin/sbcl'

    def test_swank_file_exists(self):
        bin = LispRuntime(self.swank_path, self.lisp_path)
        self.assertFalse(len(str(bin.swank_file)) == 0)

    def test_not_running_at_start(self):
        bin = LispRuntime(self.swank_path, self.lisp_path)
        self.assertFalse(bin.running)

    def test_cannot_run_without_binary_path(self):
        bin = LispRuntime(self.swank_path, None)
        bin.start()
        self.assertFalse(bin.running)
