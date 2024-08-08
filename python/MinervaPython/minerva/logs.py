from pathlib import Path
from logging import Formatter, INFO, getLogger, NullHandler
from logging.handlers import RotatingFileHandler

LOG_PATH = Path('./config/minerva.log')

log_format = Formatter('%(asctime)s: %(levelname)s: %(message)s')

# if the handler file cannot be found, return a dummy logger
try:
    handler = RotatingFileHandler(str(LOG_PATH), maxBytes=5*1024*1024,
                                  backupCount=2, encoding=None, delay=False)
    handler.setFormatter(Formatter('%(asctime)s: %(levelname)s: %(message)s'))
    handler.setLevel(INFO)
except FileNotFoundError:
    handler = NullHandler()

logger = getLogger('root')
logger.addHandler(handler)
logger.setLevel(INFO)
