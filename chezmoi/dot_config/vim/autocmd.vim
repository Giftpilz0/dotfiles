if has("autocmd")
  autocmd BufWritePre * :call StripTrailingWhitespace()
endif
