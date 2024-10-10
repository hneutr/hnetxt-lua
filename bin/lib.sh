function htc_test() {
    local START_DIR=$PWD
    cd $HOME/lib/hnetxt-lua
    luarocks make > /dev/null
    cd $START_DIR
}

function hnetxt() {
    nlua /Users/hne/lib/hnetxt-lua/src/htc/hnetxt.lua $@
}

function htt() {
    htc_test
    hnetxt $@
}

source $HOME/lib/hnetxt-lua/bin/hnetxt.sh

bindkey -s '^@' "vim @.md\n"
