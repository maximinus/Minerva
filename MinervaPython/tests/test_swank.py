from unittest import TestCase

from minerva.swank import SwankMessage


class TestMessage(TestCase):
    def test_simple_parse(self):
        sent = '(:return (:ok ("(+ &rest ===> numbers <===)" t)) 8)'
        message = SwankMessage(sent)
        self.assertTrue(len(message.ast) == 3)
