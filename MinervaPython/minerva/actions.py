from enum import Enum


class Actions(Enum):
    NEW_FILE = 0
    LOAD_FILE = 1
    SAVE_FILE = 2
    QUIT_MINERVA = 3
    RUN_CODE = 4
    DEBUG_CODE = 5
    SHOW_HELP = 6
    SHOW_ABOUT = 7


ACTION_TEXT = {
    "new_file": Actions.NEW_FILE,
    "load_file": Actions.LOAD_FILE,
    "save_file": Actions.SAVE_FILE,
    "quit_minerva": Actions.QUIT_MINERVA,
    "run_code": Actions.RUN_CODE,
    "debug_code": Actions.DEBUG_CODE,
    "show_help": Actions.SHOW_HELP,
    "show_about": Actions.SHOW_ABOUT
}
