from pathlib import Path

ROOT = Path(__file__).absolute().parent.parent
DATA_DIR = ROOT.joinpath('data')

HOME_DIR = Path("/Users/hne")
TEXT_DIR = HOME_DIR.joinpath("Documents/text")

EIDOLA_DIR = HOME_DIR.joinpath('eidola')
PEOPLE_DIR = EIDOLA_DIR.joinpath('people')

#------------------------------------------------------------------------------#
#                                 reflections                                  #
#------------------------------------------------------------------------------#
REFLECTIONS_DIR = TEXT_DIR.joinpath('written/reflections')
OLD_THOUGHTS_DIR = REFLECTIONS_DIR.joinpath('thoughts')

#------------------------------------------------------------------------------#
#                                    quotes                                    #
#------------------------------------------------------------------------------#
OLD_QUOTES_DIR = TEXT_DIR.joinpath('quotes')
NEW_QUOTES_DIR = TEXT_DIR.joinpath('_quotes')
