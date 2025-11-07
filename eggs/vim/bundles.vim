" ------------------------------------------------------------------------------
" Manager
" ------------------------------------------------------------------------------
if empty(glob('~/.config/vim/autoload/plug.vim'))
  silent !curl -fLo
    \ ~/.config/vim/autoload/plug.vim
    \ --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source /etc/vimrc | :quit | :quit
endif

" ------------------------------------------------------------------------------
" Plugins
" ------------------------------------------------------------------------------
call plug#begin(expand($HOME.'/.config/vim/bundle'))
  Plug 'vim-airline/vim-airline'
  Plug 'jacoborus/tender.vim'
call plug#end()
