from pathlib import Path
from logging import Formatter, INFO, getLogger
from logging.handlers import RotatingFileHandler

LOG_PATH = Path('./config/minerva.log')

log_format = Formatter('%(asctime)s: %(levelname)s: %(message)s')

handler = RotatingFileHandler(str(LOG_PATH), maxBytes=5*1024*1024,
                                 backupCount=2, encoding=None, delay=False)
handler.setFormatter(Formatter('%(asctime)s: %(levelname)s: %(message)s'))
handler.setLevel(INFO)

logger = getLogger('root')
logger.setLevel(INFO)
