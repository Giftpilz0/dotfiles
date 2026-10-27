set nowrap
set nomodeline
set lazyredraw
set autowrite
set novisualbell
set viminfofile=NONE
set number

set list
set listchars=tab:>-<,lead:.

set title
set titlestring=%t

set wildmenu
set wildmode=longest:full,list:full

syntax enable
set background=dark
autocmd vimenter * highlight Normal guibg=NONE ctermbg=NONE
autocmd vimenter * highlight EndOfBuffer guibg=NONE ctermbg=NONE

set autoindent
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2

set ignorecase
set incsearch
set showmatch
set smartcase
set hlsearch

if has("mouse")
  set mouse=a
endif
