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
command! -bar -nargs=1 -complete=custom,s:complete SOpen
      \ call mansion#open(<f-args>)
command! -bar -nargs=0 SOpenlast if !empty(g:LAST_SESSION)
      \ | call mansion#open(g:LAST_SESSION) | endif
command! -bar -nargs=0 SClose call mansion#close()
command! -bar -nargs=? SSave call mansion#save(<q-args>)
command! -bar -nargs=1 -complete=custom,s:complete SDelete
      \ call mansion#delete(<f-args>)
command! -bar -nargs=1 -complete=custom,s:complete SEdit
      \ call mansion#edit(<f-args>)
command! -bar -bang -complete=file -nargs=? STrack
      \ call mansion#track(<bang>0, <q-args>)
command! -bar -nargs=0 SInfo call mansion#info()
command! -bang -nargs=? -complete=custom,s:complete Restart
      \ call mansion#restart(<bang>0, <q-args>)

if !exists('g:session_no_maps')
  nnoremap <leader>sl :SList<CR>
  nnoremap <leader>ss :SSave<CR>
  nnoremap <leader>sa :exe 'SSave ' . input('Save session as: '
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

function! s:track()
  if exists('g:session_if_track')
    call mansion#save()
  endif
endfunction

function! s:save()
  if !empty(v:this_session)
    let g:LAST_SESSION = v:this_session
    if !exists('g:session_no_auto_save')
      call mansion#save()
    endif
  endif
endfunction

augroup mansion
  autocmd!
  autocmd BufEnter * call s:track()
  autocmd VimLeavePre * call s:save()
augroup END

" vim:sw=2 sts=2 fdm=marker:
