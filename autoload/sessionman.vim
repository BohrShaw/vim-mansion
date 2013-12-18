" sessionman.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if exists('g:loaded_sessionman') || !has('mksession') || &cp
  finish
endif
let g:loaded_sessionman = 1

let s:session_path_full = expand(g:session_path)
if !isdirectory(s:session_path_full)
  call mkdir(s:session_path_full, 'p')
endif

function! sessionman#open(name) " {{{1
  if a:name != '' && a:name[0] != '"'
    if has('cscope')
      silent! cscope kill -1
    endif
    try
      set eventignore=all
      execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
      let n = bufnr('%')
      execute 'silent! so ' . g:session_path . '/' . a:name
      execute 'silent! bwipeout! ' . n
    finally
      set eventignore=
      doautoall BufRead
      doautoall FileType
      doautoall BufEnter
      doautoall BufWinEnter
      doautoall TabEnter
      doautoall SessionLoadPost
    endtry
    if has('cscope')
      silent! cscope add .
    endif
    let g:LAST_SESSION = a:name
  endif
endfunction

function! sessionman#close() " {{{1
  execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
  if has('cscope')
    silent! cscope kill -1
  endif
  "unlet! g:LAST_SESSION
  let v:this_session = ''
endfunction

function! sessionman#delete(name) " {{{1
  if a:name != '' && a:name[0] != '"'
    let save_go = &guioptions
    set guioptions+=c
    setlocal modifiable
    d
    setlocal nomodifiable
    if delete(expand(g:session_path . '/' . a:name)) != 0
      redraw | echohl ErrorMsg | echo 'Error deleting "' . a:name . '" session file' | echohl None
    endif
    let &guioptions = save_go
  endif
endfunction

function! sessionman#edit(name) " {{{1
  if a:name != '' && a:name[0] != '"'
    "bwipeout!
    execute 'silent! edit ' . g:session_path . '/' . a:name
    set ft=vim
  endif
endfunction

function! sessionman#editextra(name) " {{{1
  if a:name != '' && a:name[0] != '"'
    let n = substitute(a:name, "\\.[^.]*$", '', '')
    execute 'silent! edit ' . g:session_path . '/' . n . 'x.vim'
  endif
endfunction

function! sessionman#list() " {{{1
  let w_sl = bufwinnr("__SessionList__")
  if w_sl != -1
    execute w_sl . 'wincmd w'
    return
  endif
  silent! split __SessionList__

  " Mark the buffer as scratch
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nobuflisted

  nnoremap <buffer> <silent> q :hide<CR>
  nnoremap <buffer> <silent> o :call sessionman#open(getline('.'))<CR>
  nnoremap <buffer> <silent> <CR> :call sessionman#open(getline('.'))<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :call sessionman#open(getline('.'))<CR>
  nnoremap <buffer> <silent> d :call sessionman#delete(getline('.'))<CR>
  nnoremap <buffer> <silent> e :call sessionman#edit(getline('.'))<CR>
  nnoremap <buffer> <silent> x :call sessionman#editextra(getline('.'))<CR>

  syn match Comment "^\".*"
  put ='\"-----------------------------------------------------'
  put ='\" q                        - close session list'
  put ='\" o, <CR>, <2-LeftMouse>   - open session'
  put ='\" d                        - delete session'
  put ='\" e                        - edit session'
  put ='\" x                        - edit extra session script'
  put ='\"-----------------------------------------------------'
  put =''
  let l = line(".")

  let sessions = sessionman#names()
  if sessions == ''
    syn match Error "^\" There.*"
    let sessions = '" There are no saved sessions'
  endif
  silent put =sessions

  0,1d
  execute l
  setlocal nomodifiable
  setlocal nospell
endfunction

function! sessionman#saveas(...) " {{{1
  if a:0 == 0 || a:1 == ''
    let name = input('Save session as: ', substitute(v:this_session, '.*\(/\|\\\)', '', ''))
  else
    let name = a:1
  endif
  if name != ''
    if v:version >= 700 && finddir(g:session_path, '/') == ''
      call mkdir(g:session_path, 'p')
    endif
    silent! argdel *
    let g:LAST_SESSION = name
    execute 'silent mksession! ' . g:session_path . '/' . name
    redraw | echo 'Saved session "' . name . '"'
  endif
endfunction

function! sessionman#save() " {{{1
  call sessionman#saveas(substitute(v:this_session, '.*\(/\|\\\)', '', ''))
endfunction

function! sessionman#info() " {{{1
  echo 'Last_Session: ' . (exists('g:LAST_SESSION') ? g:LAST_SESSION : '?')
  let this_session = substitute(v:this_session, '\v.*[\/]', '', '')
  echon ' | Current_Session: ' . (this_session == '' ? '?' : this_session)
  echon ' | Auto_Save_On_Exit: ' . (g:session_save_on_exit == 1 ? 'On' : 'Off')
endfunction

" Get session names
function! sessionman#names() " {{{1
  let sessions = substitute(glob(g:session_path . '/*'), '\v(^|\n)' . escape(expand(g:session_path), '\') . '[\/]', '\1', 'g')
  " Exclude extra session files ending in 'x.vim'
  return substitute(sessions, '\v(^|\n)[^\n]*x\.vim\ze(\n|$)', '', 'g')
endfunction

" vim:sw=2 sts=2 fdm=marker:
