" Show session management state

function! mansion#info#info()
  echo 'this_session:' . s:session_name(v:this_session)
        \ 'LAST_SESSION:' . s:session_name(g:LAST_SESSION)
        \ 'tracking:' . (get(g:, 'mansion_track') ? 'On' : 'Off')
        \ 'auto_save:' . (mansion#info#if_auto_save() ? 'On' : 'Off')
endfunction

function! mansion#info#if_auto_save()
  return !get(g:, 'mansion_no_auto_save') &&
        \ !(bufnr('$') == 1 && bufname('%') == '') ? 1 : 0
endfunction

function! s:session_name(path)
  if empty(a:path)
    return 'None'
  else
    return a:path =~ '\V'.escape(g:sessiondir, '\') ?
          \ substitute(a:path, '.*[/\\]', '', '') : fnamemodify(a:path, ':~:.')
  endif
endfunction
