from enum import Enum

# various constants


class SearchMessage(Enum):
    NEW_SEARCH = 0
    NEXT = 1
    PREVIOUS = 2
    CLOSE = 3
