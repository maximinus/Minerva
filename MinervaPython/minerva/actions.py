from enum import Enum

from minerva.logs import logger


ACTIONS = {
}


def get_action(action):
    if action in ACTIONS:
        return ACTIONS[action]


def add_window_actions(window):
    # actions that pertain to the window
    ACTIONS['new_file'] = window.new_file
    ACTIONS['load_file'] = window.load_file
    ACTIONS['save_file'] = window.save_file
    ACTIONS['quit_minerva'] = window.quit_minerva
    ACTIONS['run_code'] = window.run_code
    ACTIONS['debug_code'] = window.debug_code
    ACTIONS['show_help'] = window.show_help
    ACTIONS['show_about'] = window.show_about
    ACTIONS['show_preferences'] = window.show_preferences


class Target(Enum):
    EMPTY = 0
    WINDOW = 1
    CONSOLE = 2
    BUFFERS = 3
    SWANK = 4
    TREES = 5


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
