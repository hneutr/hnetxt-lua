function htc_test() {
    local START_DIR=$PWD
    cd $HOME/lib/hnetxt-lua
    luarocks --lua-version 5.1 make > /dev/null
    cd $START_DIR
}

function hnetxt() {
    luajit /Users/hne/lib/hnetxt-lua/src/htc/hnetxt.lua $@
}

function htt() {
    htc_test
    hnetxt $@
}

source $HOME/lib/hnetxt-lua/bin/hnetxt.sh

bindkey -s '^@' "vim @.md\n"
