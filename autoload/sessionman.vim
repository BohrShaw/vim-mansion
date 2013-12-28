" sessionman.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if !has('mksession') || &cp
  finish
endif
let g:loaded_sessionman = 1

let g:spath = expand(g:session_path)
if !isdirectory(g:spath)
  call mkdir(g:spath, 'p')
endif

function! sessionman#open(name) " {{{1
  if a:name != '' && a:name[0] != '"'
    try
      set eventignore=all
      execute 'silent! 1,' . bufnr('$') . 'bd!'
      let n = bufnr('%')
      execute 'silent! so ' . g:spath . '/' . a:name
      execute 'silent! bd! ' . n
    finally
      set eventignore=
      doautoall BufRead
      doautoall FileType
      doautoall BufEnter
      doautoall BufWinEnter
      doautoall TabEnter
      doautoall SessionLoadPost
    endtry
    let g:last_session = a:name
  endif
endfunction

function! sessionman#close() " {{{1
  execute 'silent! 1,' . bufnr('$') . 'bd!'
  if v:this_session != ''
    let g:last_session = v:this_session
  endif
  let v:this_session = ''
endfunction

function! sessionman#delete(name) " {{{1
  if a:name != ''
    setl modifiable | d | setl nomodifiable
    if delete(expand(g:session_path . '/' . a:name))
      echoe 'Error deleting session file: ' . a:name
    endif
  endif
endfunction

function! sessionman#edit(name) " {{{1
  if a:name != '' && a:name[0] != '"'
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
  setl buftype=nofile
  setl bufhidden=wipe
  setl noswapfile
  setl nowrap
  setl nobuflisted

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
  setl nomodifiable
  setl nospell
endfunction

function! sessionman#save(...) " {{{1
  if exists('a:1') && a:1 != ''
    let name = a:1
  else
    let name = v:this_session == '' ? input('Save the session as: ')
          \ : substitute(v:this_session, '.*[/\\]', '', '')
  endif
  if v:this_session != ''
    let g:last_session = v:this_session
  endif
  execute 'mksession! ' . g:session_path . '/' . name
  echo 'Saved session "' . name . '"'
endfunction

function! sessionman#info() " {{{1
  echo 'Last_Session: ' . (exists('g:last_session') ? g:last_session : '?')
  let this_session = substitute(v:this_session, '\v.*[\/]', '', '')
  echon ' | Current_Session: ' . (this_session == '' ? '?' : this_session)
  echon ' | Auto_Save_On_Exit: ' . (g:session_save_on_exit == 1 ? 'On' : 'Off')
endfunction

" Get session names
function! sessionman#names() " {{{1
  let sessions = substitute(glob(g:session_path . '/*'), '\v(^|\n)'
        \. escape(g:spath, '\') . '[\/]', '\1', 'g')
  " Exclude extra session files ending in 'x.vim'
  return substitute(sessions, '\v(^|\n)[^\n]*x\.vim\ze(\n|$)', '', 'g')
endfunction " }}}1

" Restart Gvim with a session optionally restored
function! sessionman#restart(bang, ...) " {{{1
  if !has('gui_running')
    echoe 'Not working under the terminal!' | return
  endif
  let is_session_given = exists('a:1') && a:1 != ''
  let session_given = is_session_given ? expand(g:session_path . '/' . a:1) : ''
  if a:bang
    let args = is_session_given ? '-S ' . session_given : ''
  else
    call sessionman#save(v:this_session == '' ? 'tmp' : '')
    let args = '-S ' . (is_session_given ? session_given : v:this_session)
  endif
  exe has('win32') ? 'silent !start '.$VIMRUNTIME.'/gvim '.args :
        \ '!gvim '.args.' &'
  exe 'qa' . (a:bang ? '!' : '')
endfunction " }}}1

" vim:sw=2 sts=2 fdm=marker:
