if exists('g:loaded_prctl')
  finish
endif
let g:loaded_prctl = 1

command! Prctl lua require('prctl').prctl()
