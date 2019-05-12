" mansion.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

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
  nnoremap <buffer> <silent> o :call <SID>list('mansion#open')<CR>
  nmap <buffer> <silent> <CR> o
  nnoremap <buffer> <silent> x :call <SID>list('<SID>delete_in_list')<CR>
  nnoremap <buffer> <silent> e :call <SID>list('mansion#edit')<CR>

  syn match Comment "^\".*"
  put ='\"-------------------------------' | 1delete
  put ='\" q       - close session list'
  put ='\" o, <CR> - open(switch) session'
  put ='\" x       - delete session'
  put ='\" e       - edit session'
  put ='\"-------------------------------'
  put =''
  let sessions = mansion#names('show_time')
  if empty(sessions)
    syn match Error "^\" There.*"
    let sessions = '" There are no saved sessions'
  endif
  put =sessions | normal '{j'

  setlocal nomodifiable
  setlocal nospell
endfunction

" Helper function for operations in the session list buffer
function! s:list(func, ...)
  let line = getline('.')
  if line[0] != '['
    return
  endif
  let session = matchstr(line, '\S\+$')
  call call(a:func, [session])
endfunction

function! s:delete_in_list(s)
  if !mansion#delete(a:s)
    setlocal modifiable | delete | setlocal nomodifiable
  endif
endfunction

" Get the session names in the global session directory
function! mansion#names(...)
  let sessions = glob(g:mansion_path.'*', 1, 1)
  let r = []
  for s in sessions
    let time = a:0 ? '['.strftime('%Y-%m-%d %H:%M:%S', getftime(s)).'] ' : ''
    cal add(r, time.fnamemodify(s, ':t'))
  endfor
  return reverse(sort(r))
endfunction "}}}1

" Merge, close, open(switch), edit, save, delete a session
function! mansion#merge(name) "{{{1
  execute 'source '.s:session_path(a:name)
endfunction

function! mansion#close()
  try
    bmodified
    echohl WarningMsg | echo "Buffers modified." | echohl NONE
  catch
    %bdelete!
    let v:this_session = ''
  endtry
endfunction

function! mansion#open(name)
  if a:name == ''
    return ''
  endif
  call mansion#close()
  call mansion#merge(a:name)
endfunction

function! mansion#edit(name)
  execute 'tabedit ' . s:session_path(a:name)
  tabmove -1
endfunction

function! mansion#save(...)
  let file = s:session_path(get(a:, 1, ''))
  execute 'mksession! '.file
  if exists('a:2')
    echo ' "'.fnamemodify(file, ':~').'" saved.'
  endif
  return ''
endfunction

" Periodically save the current session.
function! mansion#save_on_timer(id)
  let s = v:this_session == '' ||
        \   get(split(v:this_session, '[/\\]'), -1) ==? 'session.vim' ?
        \ strftime('%Y%m%d_%H%M%S') : ''
  call mansion#save(s)
endfunction

function! mansion#delete(name)
  if delete(s:session_path(a:name))
    echoerr 'Error deleting session file: ' . a:name
    return 1
  endif
endfunction "}}}1

" Update the session file continuously, or stop updating it and delete it
" optionally
function! mansion#follow(bang, file) abort "{{{1
  let file = s:session_path(a:file)
  let file_friendly = fnamemodify(file, ':~:.')
  if a:bang || exists('g:mansion_follow') && empty(a:file)
    autocmd! mansion BufWinEnter
    unlet! g:mansion_follow
    if a:bang
      call delete(file)
      echo 'Delete the session: ' . file_friendly
    else
      echo 'Stop following the session: '.file_friendly
    endif
  else
    let v:this_session = file
    autocmd! mansion BufWinEnter * if empty(&buftype) |
          \call mansion#save() | endif
    doautocmd mansion BufWinEnter
    let g:mansion_follow = 1
    echo 'Follow the session: '.file_friendly
  endif
endfunction "}}}1

" Get the full path of a session file
function! s:session_path(...) "{{{1
  if !a:0 || empty(a:1)
    let path = empty(v:this_session) ? g:mansion_path.'Session.vim' : v:this_session
  elseif filereadable(expand(a:1))
    let path = fnamemodify(expand(a:1), ':p')
  elseif a:1 =~# '\v^[^/\\]+$'
    let path = g:mansion_path . a:1
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
    let g:mansion_no_save_on_exit = 1
    let args = empty(session) ? '' : '-S ' . session_path
  else
    unlet! g:mansion_no_save_on_exit
    wall | let args = '-S ' . session_path
  endif
  wviminfo " save viminfo before starting a new instance
  execute has('win32') ?
        \ 'silent !start '.$VIMRUNTIME.'/gvim '.args : '!gvim '.args.' &'
  set viminfo= " no writing anymore upon exit
  execute 'qa' . (a:bang ? '!' : '')
endfunction "}}}1

" vim:sw=2 sts=2 fdm=marker:
