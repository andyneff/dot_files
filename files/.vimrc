colorscheme elflord
syntax on
set mouse=a

if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

if v:version < 802
  " Make Ctrl+q work, so that I can use Visual Block Mode on Windows Terminal where Ctrl+v is paste clipboard
  silent !stty -ixon > /dev/null 2>/dev/null
endif

set backspace=indent,eol,start
