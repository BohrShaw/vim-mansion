" Show session management state

function! mansion#info#info()
  echo s:session_name(v:this_session).'('.
        \ (get(g:, 'mansion_follow') ? '' : 'no-').'follow, '.
        \ (mansion#info#save_on_exit() ? '' : 'no-').'save_on_exit)'
        \ '('.s:session_name(g:LAST_SESSION).')'
endfunction

function! mansion#info#save_on_exit()
  return !get(g:, 'mansion_no_save_on_exit') &&
        \ !(bufnr('$') == 1 && bufname('%') == '') ? 1 : 0
endfunction

function! s:session_name(path)
  if empty(a:path)
    return 'None'
  else
    return a:path =~ '\V'.escape(g:mansion_path, '\') ?
          \ substitute(a:path, '.*[/\\]', '', '') : fnamemodify(a:path, ':~:.')
  endif
endfunction
