function hnetxt() {
    luajit $HOME/lib/hnetxt-lua/src/htc/init.lua $@
}

function hnetxt_test() {
    local START_DIR=$PWD
    cd $HOME/lib/hnetxt-lua
    luarocks --lua-version 5.1 make > /dev/null
    cd $START_DIR
    hnetxt $@
}

function journal() {
    nvim $(hnetxt journal $@) -c "lua require('zen-mode').toggle()"
}

function track() {
    nvim $(hnetxt track $@)
}

function aim() {
    nvim $(hnetxt aim $@)
}

function quote() {
    nvim $(hnetxt quote $@) +"lua require('htn.ui').quote()"
}

function lang() {
    cd $(hnetxt language)
}

alias tax="hnetxt tax"
alias ref="hnetxt ref"
alias project="hnetxt project"

alias ht="hnetxt"
alias htt="hnetxt_test"

alias mv="hnetxt move"
alias rm="hnetxt remove"
