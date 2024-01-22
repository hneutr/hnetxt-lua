from pathlib import Path

ROOT = Path(__file__).absolute().parent.parent
PY_DATA_DIR = ROOT / 'data'
TEST_DATA_DIR = PY_DATA_DIR / 'test-track-log'
FIGURES_DIR = PY_DATA_DIR / 'figures'
HOME = Path.home()

DATA_DIR = HOME / '.data'
DASHBOARDS_DIR = DATA_DIR / 'dashboards'

CONFIG_DIR = HOME / 'lib' / 'hnetxt-lua' / 'scripts' / 'constants'
EMOJI_DIR = CONFIG_DIR / 'emoji'

X_OF_THE_DAY_DIR = DATA_DIR / 'x-of-the-day'
QUOTE_OF_THE_DAY_DIR = X_OF_THE_DAY_DIR / 'quote'
QUESTION_OF_THE_DAY_DIR = X_OF_THE_DAY_DIR / 'question'

EIDOLA_DIR = HOME / 'eidola'
PEOPLE_DIR = EIDOLA_DIR / 'people'

TEXT_DIR = HOME / "Documents/text"

###------------------------------------------------------------------------------#
#                                     lua                                      #
#------------------------------------------------------------------------------#
LUA_ROOT = Path.home() / 'lib' / 'hnetxt-lua'

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

#------------------------------------------------------------------------------#
#                               run-x-of-the-day                               #
#------------------------------------------------------------------------------#
RUN_X_OF_THE_DAY_COMMAND = "/Users/hne/dotfiles/hnetxt/set-x-of-the-day.sh"
RUN_X_OF_THE_DAY_ENV = {
    'SHELL': '/bin/zsh',
    'HOME': '/Users/hne',
    'DOTFILES': '/Users/hne/dotfiles',
    'PATH': '/opt/homebrew/Cellar/pyenv-virtualenv/1.2.1/shims:/Users/hne/.pyenv/shims:/opt/homebrew:/opt/homebrew:/opt/homebrew/Cellar/pyenv-virtualenv/1.2.1/shims:/opt/homebrew:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/TeX/texbin:/Applications/kitty.app/Contents/MacOS:/opt/homebrew/opt/fzf/bin',
}
