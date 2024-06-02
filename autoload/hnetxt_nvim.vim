function! hnetxt_nvim#foldexpr() abort
    return luaeval(printf('require("htn.ui.fold").get_indic(%d)', v:lnum))
endfunction
