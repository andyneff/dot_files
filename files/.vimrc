colorscheme elflord
syntax on
set mouse=a

if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

set backspace=indent,eol,start
