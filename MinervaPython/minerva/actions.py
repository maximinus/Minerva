from enum import Enum

from minerva.logs import logger


class Target(Enum):
    EMPTY = 0
    WINDOW = 1
    CONSOLE = 2
    TEXT = 3
    SWANK = 4
    TREES = 5


def get_named_action(name):
    # match the name else return None
    match name:
        case 'main':
            return Target.WINDOW
        case 'console':
            return Target.CONSOLE
        case 'text':
            return Target.TEXT
        case 'swank':
            return Target.SWANK
        case 'trees':
            return Target.TREES


class Message:
    def __init__(self, address, action=None, data=None):
        # the address is one of the targets
        self.address = address
        self.action = action
        self.data = data

    def __repr__(self):
        return f'{Target(self.address)}:{self.action}'


class Messenger:
    def __init__(self):
        self.messages = []
        # resolver is the function to call when we need to action the messages
        self.resolver = None

    def set_resolver(self, resolver):
        self.resolver = resolver

    def message(self, message):
        if self.resolver is None:
            logger.error(f'Cannot resolve {message} as no resolver')
            return
        self.resolver(message)


message_queue = Messenger()
