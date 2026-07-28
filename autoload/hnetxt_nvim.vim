function! hnetxt_nvim#foldexpr() abort
    return luaeval(printf('require("htn.ui").get_foldlevel(%d)', v:lnum))
endfunction
