" mansion.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if !exists('g:sessiondir')
  let g:sessiondir = '~/.vim/session'
endif
let s:sessiondir = fnamemodify(expand(g:sessiondir), ':p')
if !isdirectory(s:sessiondir)
  call mkdir(s:sessiondir, 'p')
endif

" Open a window to manage sessions
function! mansion#list() "{{{1
  let session_winnr = bufwinnr("__SessionList__")
  if session_winnr != -1
    execute session_winnr . 'wincmd w'
    return
  endif
  silent! split __SessionList__

  setlocal buftype=nofile nobuflisted bufhidden=wipe

  nnoremap <buffer> <silent> q :hide<CR>
  nnoremap <buffer> <silent> o :call mansion#func('open(getline("."))')<CR>
  nmap <buffer> <silent> <CR> o
  nnoremap <buffer> <silent> d :call mansion#func('delete_in_list()')<CR>
  nnoremap <buffer> <silent> e :call mansion#func('edit(getline("."))')<CR>

  syn match Comment "^\".*"
  put ='\"-------------------------------' | 1delete
  put ='\" q       - close session list'
  put ='\" o, <CR> - open(switch) session'
  put ='\" d       - delete session'
  put ='\" e       - edit session'
  put ='\"-------------------------------'
  put =''
  let sessions = mansion#names()
  if sessions == ''
    syn match Error "^\" There.*"
    let sessions = '" There are no saved sessions'
  endif
  put =sessions | normal '{j'

  setlocal nomodifiable
  setlocal nospell
endfunction

function! mansion#func(str)
  if getline('.') =~ '^[^"]'
    call eval('mansion#' . a:str)
  endif
endfunction

function! mansion#delete_in_list()
  if !mansion#delete(getline('.'))
    setlocal modifiable | delete | setlocal nomodifiable
  endif
endfunction

" Get the session names in the global session directory
function! mansion#names()
  return substitute(glob(s:sessiondir.'*'), '[^\n]*[/\\]', '', 'g')
endfunction "}}}1

" Merge, close, open(switch), edit, save, delete a session
function! mansion#merge(name) "{{{1
  execute 'source '.s:session_path(a:name)
endfunction

function! mansion#close()
  try
    %bdelete
  catch
    echohl WarningMsg | echo "Changed buffers remain." | echohl NONE
  finally
    let v:this_session = ''
  endtry
endfunction

function! mansion#open(name)
  call mansion#close()
  call mansion#merge(a:name)
endfunction

function! mansion#edit(name)
  execute 'tabedit ' . s:session_path(a:name)
endfunction

function! mansion#save(...)
  execute 'mksession! '.s:session_path(get(a:, 1, ''))
  return ''
endfunction

function! mansion#delete(name)
  if delete(s:session_path(a:name))
    echoerr 'Error deleting session file: ' . a:name
    return 1
  endif
endfunction "}}}1

" Update the session file continuously, or stop updating it and delete it
" optionally
function! mansion#track(bang, file) abort "{{{1
  let file = s:session_path(a:file)
  let file_friendly = fnamemodify(file, ':~:.')
  if a:bang || exists('g:mansion_track') && empty(a:file)
    autocmd! mansion BufWinEnter
    unlet! g:mansion_track
    if a:bang
      call delete(file)
      echo 'Delete the session: ' . file_friendly
    else
      echo 'Stop tracking the session: '.file_friendly
    endif
  else
    let v:this_session = file
    autocmd! mansion BufWinEnter * if empty(&buftype) |
          \call mansion#save() | endif
    doautocmd mansion BufWinEnter
    let g:mansion_track = 1
    echo 'Track the session: '.file_friendly
  endif
endfunction "}}}1

" Get the full path of a session file
function! s:session_path(...) "{{{1
  if !a:0 || empty(a:1)
    let path = empty(v:this_session) ? s:sessiondir.'Session.vim' : v:this_session
  elseif filereadable(a:1)
    let path = fnamemodify(expand(a:1), ':p')
  elseif isdirectory(a:1)
    let path = fnamemodify(expand(a:1), ':p') . 'Session.vim'
  elseif a:1 =~# '\v^[^/\\]+$'
    let path = s:sessiondir . a:1
  else
    throw 'Invalid session path: '.a:1
    return
  endif
  return path
endfunction "}}}1

" Restart Gvim with a session optionally restored
function! mansion#restart(bang, ...) "{{{1
  if !has('gui_running')
    echoerr 'Not working under the terminal!' | return
  endif
  let session = get(a:, 1, '')
  let session_path = s:session_path(session)
  if a:bang
    let g:mansion_no_auto_save = 1
    let args = empty(session) ? '' : '-S ' . session_path
  else
    unlet! g:mansion_no_auto_save
    wall | let args = '-S ' . session_path
  endif
  wviminfo " save viminfo before starting a new instance
  execute has('win32') ?
        \ 'silent !start '.$VIMRUNTIME.'/gvim '.args : '!gvim '.args.' &'
  set viminfo= " no writing anymore upon exit
  execute 'qa' . (a:bang ? '!' : '')
endfunction "}}}1

" vim:sw=2 sts=2 fdm=marker:
