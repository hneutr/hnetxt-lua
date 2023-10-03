let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/lib/hnetxt-lua
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +1 src/htl/text/header.lua
badd +7 spec/hs/header_spec.lua
badd +1 spec/htl/text/header_spec.lua
badd +102 term://~/lib/hnetxt-lua//1112:/bin/zsh
badd +40 term://~/lib/hnetxt-lua//1362:/bin/zsh
badd +28 term://~/lib/hnetxt-lua//1658:/bin/zsh
badd +0 term://~/lib/hnetxt-lua//1857:/bin/zsh
argglobal
%argdel
$argadd src/htl/text/header.lua
edit src/htl/text/header.lua
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
wincmd _ | wincmd |
split
1wincmd k
wincmd w
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 122 + 123) / 246)
exe '2resize ' . ((&lines * 40 + 41) / 83)
exe 'vert 2resize ' . ((&columns * 123 + 123) / 246)
exe '3resize ' . ((&lines * 40 + 41) / 83)
exe 'vert 3resize ' . ((&columns * 123 + 123) / 246)
argglobal
balt spec/hs/header_spec.lua
setlocal fdm=indent
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=1
setlocal nofen
let s:l = 49 - ((40 * winheight(0) + 40) / 81)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 49
normal! 03|
wincmd w
argglobal
if bufexists(fnamemodify("spec/htl/text/header_spec.lua", ":p")) | buffer spec/htl/text/header_spec.lua | else | edit spec/htl/text/header_spec.lua | endif
if &buftype ==# 'terminal'
  silent file spec/htl/text/header_spec.lua
endif
balt spec/hs/header_spec.lua
setlocal fdm=indent
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=1
setlocal nofen
let s:l = 2 - ((1 * winheight(0) + 20) / 40)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 2
normal! 0
wincmd w
argglobal
if bufexists(fnamemodify("term://~/lib/hnetxt-lua//1857:/bin/zsh", ":p")) | buffer term://~/lib/hnetxt-lua//1857:/bin/zsh | else | edit term://~/lib/hnetxt-lua//1857:/bin/zsh | endif
if &buftype ==# 'terminal'
  silent file term://~/lib/hnetxt-lua//1857:/bin/zsh
endif
balt spec/htl/text/header_spec.lua
setlocal fdm=indent
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=1
setlocal nofen
let s:l = 124 - ((39 * winheight(0) + 20) / 40)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 124
normal! 019|
wincmd w
exe 'vert 1resize ' . ((&columns * 122 + 123) / 246)
exe '2resize ' . ((&lines * 40 + 41) / 83)
exe 'vert 2resize ' . ((&columns * 123 + 123) / 246)
exe '3resize ' . ((&lines * 40 + 41) / 83)
exe 'vert 3resize ' . ((&columns * 123 + 123) / 246)
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let &winminheight = s:save_winminheight
let &winminwidth = s:save_winminwidth
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
nohlsearch
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
