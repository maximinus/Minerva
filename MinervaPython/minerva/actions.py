from enum import Enum

# we need a hash table of actions and the functions to call
# we don't care where the functions are, however maybe we want to namespace them (?)

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
