from pathlib import Path

ROOT = Path(__file__).absolute().parent.parent
HOME = Path.home()

CONFIG_DIR = HOME / 'lib' / 'hnetxt-lua' / 'constants'

DATA_DIR = HOME / '.data'
DASHBOARDS_DIR = DATA_DIR / 'dashboards'
DB_PATH = DATA_DIR / '.htl-0.0.0.db'

X_OF_THE_DAY_DIR = DATA_DIR / 'x-of-the-day'
QUOTE_OF_THE_DAY_DIR = X_OF_THE_DAY_DIR / 'quote'
QUESTION_OF_THE_DAY_DIR = X_OF_THE_DAY_DIR / 'question'
