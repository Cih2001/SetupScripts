let c='a'
while c <= 'z'
  exec "set <A-".c.">=\e".c
  exec "imap \e".c." <A-".c.">"
  let c = nr2char(1+char2nr(c))
endw
set ttimeout ttimeoutlen=50

noremap <A-a> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

set path+=**
set wildmenu

command! Wq :wq
command! W :w

set shiftwidth=4 softtabstop=4 tabstop=4 expandtab

set rnu
set nu
set showcmd
set autoindent
set laststatus=2
set statusline=%f%m%r%h%w\ [%Y]\ [0x%02.2B]%<\ %F%4v,%4l\ %3p%%\ of\ %L\ lines


