nmap <buffer> // I//<Esc>
nnoremap <space>f ofunction () {<CR>}<esc>kf<space>a
inoremap ,f function () {<CR>}<esc>kf<space>a
" Because xhr.js.vim have 10 lines. How to use a var?
inoremap ,x <esc>:-1r ~/.vim/templates/xhr.js.vim<cr> 10==
inoremap ,c console.log();<esc>hi
