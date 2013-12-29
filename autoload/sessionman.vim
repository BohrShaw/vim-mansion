" sessionman.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if !exists('g:sessiondir')
  let g:sessiondir = '~/.vim/sessions'
endif
let s:sessiondir = fnamemodify(expand(g:sessiondir), ':p')
if !isdirectory(s:sessiondir)
  call mkdir(s:sessiondir, 'p')
endif

" Open a window to manage sessions
function! sessionman#list() "{{{1
  let session_winnr = bufwinnr("__SessionList__")
  if session_winnr != -1
    execute session_winnr . 'wincmd w'
    return
  endif
  silent! split __SessionList__

  setlocal buftype=nofile nobuflisted bufhidden=wipe

  nnoremap <buffer> <silent> q :hide<CR>
  nnoremap <buffer> <silent> o :exe sessionman#func('open(getline("."))')<CR>
  nmap <buffer> <silent> <CR> o
  nnoremap <buffer> <silent> d :exe sessionman#func('delete_in_list()')<CR>
  nnoremap <buffer> <silent> e :exe sessionman#func('edit(getline("."))')<CR>

  syn match Comment "^\".*"
  put ='\"------------------------------' | 1delete
  put ='\" q       - close session list'
  put ='\" o, <CR> - open session'
  put ='\" d       - delete session'
  put ='\" e       - edit session'
  put ='\"------------------------------'
  put =''
  let sessions = sessionman#names()
  if sessions == ''
    syn match Error "^\" There.*"
    let sessions = '" There are no saved sessions'
  endif
  put =sessions | normal '{j'

  setlocal nomodifiable
  setlocal nospell
endfunction

function! sessionman#func(str)
  return eval('getline(".") =~ "^[^\"]" ? sessionman#' . a:str . ' : ""')
endfunction

function! sessionman#delete_in_list()
  if !sessionman#delete(getline('.'))
    setlocal modifiable | delete | setlocal nomodifiable
  endif
endfunction

" Get the session names in the global session directory
function! sessionman#names()
  return substitute(glob(s:sessiondir.'*'), '[^\n]*[/\\]', '', 'g')
endfunction "}}}1

" Open a session after the current session is closed
function! sessionman#open(name) "{{{1
  call sessionman#close()
  let n = bufnr('%')
  execute 'silent! so ' . s:session_path(a:name)
  execute 'silent! bd! ' . n
endfunction "}}}1

" Delete all buffers in the current session
function! sessionman#close() "{{{1
  set eventignore=all
  execute 'silent! 1,' . bufnr('$') . 'bd!'
  set eventignore=
  let v:this_session = ''
endfunction "}}}1

" Delete a session file
function! sessionman#delete(name) "{{{1
  if delete(s:session_path(a:name))
    echoerr 'Error deleting session file: ' . a:name
    return 1
  endif
endfunction "}}}1

" Edit a session file
function! sessionman#edit(name) "{{{1
  execute 'tabedit ' . s:session_path(a:name)
endfunctio "}}}1

" Save a session file
function! sessionman#save(...) "{{{1
  let file = s:session_path(exists('a:1') ? a:1 : '')
  execute 'mksession! ' . file
endfunction "}}}1

" Update the session file continuously, or stop updating it and delete it
" optionally
function! sessionman#track(bang, file) abort "{{{1
  let file = s:session_path(a:file)
  let file_friendly = fnamemodify(file, ':~:.')
  if a:bang
    echo 'Delete the session: ' . file_friendly
    call delete(file)
    unlet! g:session_if_track
  elseif exists('g:session_if_track') && empty(a:file)
    echo 'Stop tracking the session: '.file_friendly
    unlet g:session_if_track
  else
    echo 'Track the session: '.file_friendly
    let v:this_session = file
    call sessionman#save(file)
    let g:session_if_track = 1
  endif
endfunction "}}}1

" Show session management state
function! sessionman#info() "{{{1
  echo 'Session(' . s:session_name(v:this_session) . ')'
        \ 'tracking:' . (exists('g:session_if_track') ? 'On' : 'Off')
        \ 'auto-save:' . (exists('g:session_no_auto_save') ? 'Off' : 'On')
        \ 'last-session:' . s:session_name(g:LAST_SESSION)
endfunction

function! s:session_name(path)
  if empty(a:path)
    return 'None'
  else
    return a:path =~ '\V'.escape(s:sessiondir, '\') ?
          \ substitute(a:path, '.*[/\\]', '', '') : fnamemodify(a:path, ':~:.')
  endif
endfunction "}}}1

" Get the full path of a session file
function! s:session_path(...) "{{{1
  let file = exists('a:1') ? a:1 : ''
  if empty(file)
    let path = empty(v:this_session) ? s:sessiondir.'Session.vim' : v:this_session
  elseif file !~# '[/\\]'
    let path = s:sessiondir . file
  elseif isdirectory(file)
    let path = fnamemodify(expand(file), ':p') . 'Session.vim'
  else
    let path = fnamemodify(expand(file), ':p')
  endif
  return path
endfunction "}}}1

" Restart Gvim with a session optionally restored
function! sessionman#restart(bang, ...) "{{{1
  if !has('gui_running')
    echoerr 'Not working under the terminal!' | return
  endif
  let session = exists('a:1') ? a:1 : ''
  let session_path = s:session_path(session)
  if a:bang
    unlet! g:session_no_auto_save
    let args = empty(session) ? '' : '-S ' . session_path
  else
    if exists('g:session_no_auto_save')
      call sessionman#save(session_path)
    endif
    let args = '-S ' . session_path
  endif
  execute has('win32') ?
        \ 'silent !start '.$VIMRUNTIME.'/gvim '.args : '!gvim '.args.' &'
  execute 'qa' . (a:bang ? '!' : '')
endfunction "}}}1

" vim:sw=2 sts=2 fdm=marker:
