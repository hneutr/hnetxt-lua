function htc_test() {
    local START_DIR=$PWD
    cd $HOME/lib/hnetxt-lua
    luarocks --lua-version 5.1 make > /dev/null
    cd $START_DIR
}

for file in $HOME/lib/hnetxt-lua/bin/*(.); do source $file; done

function journal() {
    nvim $(hnetxt journal) -c "lua require('zen-mode').toggle()"
}

function track() {
    nvim $(hnetxt track)
}

function aim() {
    nvim $(hnetxt aim)
}

function quote() {
    nvim $(hnetxt quote) +"lua require('htn.ui').quote($1)"
}

# function define() {
#     nvim $(hnetxt define $@)
# }
#
alias ht="hnetxt"
alias htt="thnetxt"

alias on="hnetxt on"
alias mv="hnetxt move"
alias rm="hnetxt remove"
alias ety="hnetxt ety"

bindkey -s '^@' "vim @.md\n"
