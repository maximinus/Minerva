from unittest import TestCase

from minerva.swank import SwankMessage


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
