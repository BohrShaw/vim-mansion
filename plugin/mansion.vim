" mansion.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if exists("g:loaded_mansion") || !has('mksession') || &cp
  finish
endif
let g:loaded_mansion = 1

if !exists('g:LAST_SESSION')
  let g:LAST_SESSION = ''
endif

function! s:complete(A, L, P)
  return mansion#names()
endfunction

command! -bar -nargs=0 SList call mansion#list()
command! -bar -nargs=1 -complete=custom,s:complete SMerge call mansion#merge(<f-args>)
command! -bar -nargs=1 -complete=custom,s:complete SOpen call mansion#open(<f-args>)
command! -bar -nargs=0 SOpenlast execute empty(g:LAST_SESSION) ?
      \ 'echo "Last session unknown"' : 'SOpen '.g:LAST_SESSION
command! -bar -nargs=0 SClose call mansion#close()
command! -bar -nargs=? SSave call mansion#save(<q-args>)
command! -bar -nargs=1 -complete=custom,s:complete SDelete call mansion#delete(<f-args>)
command! -bar -nargs=1 -complete=custom,s:complete SEdit call mansion#edit(<f-args>)
command! -bar -bang -complete=custom,s:complete -nargs=? STrack
      \ call mansion#track(<bang>0, <q-args>)
command! -bar -nargs=0 SInfo call mansion#info()
command! -bang -nargs=? -complete=custom,s:complete Restart
      \ call mansion#restart(<bang>0, <q-args>)

if !get(g:, 'mansion_no_maps')
  nnoremap <leader>sl :SList<CR>
  nnoremap <leader>ss :SSave<CR>
  nnoremap <leader>sS :let g:mansion_no_auto_save = get(g:, 'mansion_no_auto_save') ? 0 : 1 \|
        \ echo (g:mansion_no_auto_save ? 'no ' : '') . 'auto saving the session'<CR>
  nnoremap <leader>sa :execute 'SSave ' . input('Save session as: '
        \ , substitute(v:this_session, '.*[/\\]', '', 'NONE'))<CR>
  nnoremap <leader>st :STrack<CR>
  nnoremap <leader>si :SInfo<CR>
endif

if exists('did_install_default_menus')
  anoremenu 10.370 &File.-SessionsSep- <Nop>
  anoremenu 10.371 &File.S&essions.&Open\.\.\. :SList<CR>
  anoremenu 10.372 &File.S&essions.Open\ &Last :SOpenlast<CR>
  anoremenu 10.373 &File.S&essions.&Close :SClose<CR>
  anoremenu 10.374 &File.S&essions.&Save :SSave<CR>
  anoremenu 10.375 &File.S&essions.Save\ &As\.\.\. :execute 'SSave '
        \ . inputdialog('Save the session as: '
        \ , substitute(v:this_session, '.*[/\\]', '', ''), 'NONE')<CR>
endif

augroup mansion
  autocmd! VimLeavePre * execute mansion#if_auto_save() ? mansion#save() : ''|
        \ let g:LAST_SESSION = empty(v:this_session) ? '' : v:this_session
augroup END

" vim:sw=2 sts=2 fdm=marker nowrap:
