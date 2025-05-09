" ------------------------------------------------------------------------------
" Autocommand
" ------------------------------------------------------------------------------

if has("autocmd")
  " Automatically removing all trailing whitespace
  autocmd BufWritePre * :call StripTrailingWhitespace()
endif
