" mansion.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if exists("g:loaded_mansion") || !has('mksession') || &cp
  finish
endif
let g:loaded_mansion = 1

let g:mansion_path = expand(get(g:, 'sessiondir', '~/.vim/session'))
if !isdirectory(g:mansion_path)
  call mkdir(g:mansion_path, 'p')
endif
" Append a path separator after the directory exists.
let g:mansion_path = fnamemodify(g:mansion_path, ':p')

function! s:complete(A, L, P)
  return mansion#names()
endfunction

command! -bar -nargs=0 SessionList call mansion#list()
command! -bar -nargs=1 -complete=custom,s:complete SessionMerge call mansion#merge(<f-args>)
command! -bar -nargs=1 -complete=custom,s:complete SessionOpen call mansion#open(<f-args>)
command! -bar -nargs=0 SessionClose call mansion#close()
command! -bar -nargs=? SessionSave call mansion#save(<q-args>)
command! -bar -nargs=1 -complete=custom,s:complete SessionDelete call mansion#delete(<f-args>)
command! -bar -nargs=1 -complete=custom,s:complete SessionEdit call mansion#edit(<f-args>)
command! -bar -bang -complete=custom,s:complete -nargs=? SessionTrack
      \ call mansion#track(<bang>0, <q-args>)
command! -bar -nargs=0 SessionInfo call mansion#info#info()
command! -bang -nargs=? -complete=custom,s:complete Restart
      \ call mansion#restart(<bang>0, <q-args>)

if !get(g:, 'mansion_no_maps')
  nnoremap ys<Space> :Session
  nnoremap ysl :SessionList<CR>
  nnoremap yso :call mansion#open(g:LAST_SESSION)<CR>
  nnoremap yss :SessionSave<CR>
  nnoremap ysa :execute 'SessionSave ' . input('Save session as: '
        \ , substitute(v:this_session, '.*[/\\]', '', 'NONE'))<CR>
  nnoremap ysS :let g:mansion_no_auto_save = get(g:, 'mansion_no_auto_save') ? 0 : 1 \|
        \ echo (g:mansion_no_auto_save ? 'no ' : '') . 'auto saving the session'<CR>
  nnoremap yst :SessionTrack<CR>
  nnoremap ysi :SessionInfo<CR>
endif

if exists('did_install_default_menus')
  anoremenu 10.370 &File.-SessionsSep- <Nop>
  anoremenu 10.371 &File.S&essions.&Open\.\.\. :SessionList<CR>
  anoremenu 10.372 &File.S&essions.Open\ &Last :call mansion#open(g:LAST_SESSION)<CR>
  anoremenu 10.373 &File.S&essions.&Close :SessionClose<CR>
  anoremenu 10.374 &File.S&essions.&Save :SessionSave<CR>
  anoremenu 10.375 &File.S&essions.Save\ &As\.\.\. :execute 'SessionSave '
        \ . inputdialog('Save the session as: '
        \ , substitute(v:this_session, '.*[/\\]', '', ''), 'NONE')<CR>
endif

augroup mansion
  " Note: Unlike v:this_session, g:LAST_SESSION remains the same until next
  " restart. And it shouldn't be stored in a full path format due to
  " incompatibility between '/c/...' and 'C:\...'.
  autocmd! VimLeavePre * execute mansion#info#if_auto_save() ? mansion#save() : ''|
        \ if !empty(v:this_session) |
        \ let g:LAST_SESSION = substitute(fnamemodify(v:this_session, ':~'), '\\', '/', 'g') |
        \ endif
  " g:LAST_SESSION is restored from viminfo file.
  autocmd VimEnter * let g:LAST_SESSION = exists('g:LAST_SESSION') ?
        \ expand(g:LAST_SESSION, ':p') : ''
augroup END

" vim:sw=2 sts=2 fdm=marker nowrap:
