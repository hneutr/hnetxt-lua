from pathlib import Path

ROOT = Path(__file__).absolute().parent.parent
PY_DATA_DIR = ROOT / 'data'
TEST_DATA_DIR = PY_DATA_DIR / 'test-track-log'
FIGURES_DIR = PY_DATA_DIR / 'figures'
HOME = Path.home()

DATA_DIR = HOME / '.data'

CONFIG_DIR = HOME / 'dotfiles' / 'hnetxt' / 'constants'
EMOJI_DIR = CONFIG_DIR / 'emoji'


EIDOLA_DIR = HOME / 'eidola'
PEOPLE_DIR = EIDOLA_DIR / 'people'

TEXT_DIR = HOME / "Documents/text"

###------------------------------------------------------------------------------#
#                                     lua                                      #
#------------------------------------------------------------------------------#
LUA_ROOT = Path.home() / 'lib' / 'hnetxt-lua'
TRACKER_SCRIPT = LUA_ROOT / 'scripts' / 'generate_tracker_csv.lua'

#------------------------------------------------------------------------------#
#                                 reflections                                  #
#------------------------------------------------------------------------------#
REFLECTIONS_DIR = TEXT_DIR / 'written/reflections'
OLD_THOUGHTS_DIR = REFLECTIONS_DIR / 'thoughts'

#------------------------------------------------------------------------------#
#                                    quotes                                    #
#------------------------------------------------------------------------------#
OLD_QUOTES_DIR = TEXT_DIR / 'quotes'
NEW_QUOTES_DIR = TEXT_DIR / '_quotes'
