" Show session management state

function! mansion#info#info()
  echo s:session_name(v:this_session).'('.
        \ (get(g:, 'mansion_track') ? '' : 'no-').'tracking, '.
        \ (mansion#info#if_auto_save() ? '' : 'no-').'auto_saving)'
        \ '('.s:session_name(g:LAST_SESSION).')'
endfunction

function! mansion#info#if_auto_save()
  return !get(g:, 'mansion_no_auto_save') &&
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
