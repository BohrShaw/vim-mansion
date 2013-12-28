" sessionman.vim - Vim session manager
" Author: Bohr Shaw <pubohr@gmail.com>

if !exists('g:session_path')
  let g:session_path = '~/.vim/sessions'
endif

if !exists('g:session_save_on_exit')
  let g:session_save_on_exit = 0
endif

function! SessionComplete(A, L, P)
  return sessionman#names()
endfunction

" Commands
command! -bar -nargs=0 SessionList call sessionman#list()
command! -bar -nargs=1 -complete=custom,SessionComplete SessionOpen
      \ call sessionman#open(<f-args>)
command! -bar -nargs=0 SessionOpenlast if exists('g:LAST_SESSION')
      \ | call sessionman#open(g:LAST_SESSION) | endif
command! -bar -nargs=0 SessionClose call sessionman#close()
command! -bar -nargs=? SessionSave call sessionman#save(<q-args>)
command! -bar -nargs=1 -complete=custom,SessionComplete SessionDelete
      \ call sessionman#delete(<f-args>)
command! -bar -nargs=1 -complete=custom,SessionComplete SessionEdit
      \ call sessionman#edit(<f-args>)
command! -bar -nargs=0 SessionInfo call sessionman#info()
command! -bang -nargs=? -complete=custom,SessionComplete Restart
      \ call sessionman#restart(<bang>0, <q-args>)

" Auto commands
aug sessionman
  au VimLeavePre * if g:session_save_on_exit && v:this_session != ''
        \ | call sessionman#save() | endif
aug END

" Add menu items
if exists('did_install_default_menus')
  an 10.370 &File.-SessionsSep- <Nop>
  an 10.371 &File.S&essions.&Open\.\.\. :SessionList<CR>
  an 10.372 &File.S&essions.Open\ &Last :SessionOpenlast<CR>
  an 10.373 &File.S&essions.&Close :SessionClose<CR>
  an 10.374 &File.S&essions.&Save :SessionSave<CR>
  an 10.375 &File.S&essions.Save\ &As\.\.\. :SessionSaveas<CR>
endif

" vim:sw=2 sts=2 fdm=marker:
