# Vim session manager
Make session management convenient and delightful.

## Features
A session management window like this:

    q                        - close session list
    o, <CR>, <2-LeftMouse>   - open session
    d                        - delete session
    e                        - edit session
    x                        - edit extra session script

Check source for available commands.

## Configuration
The central location of sessions:

    let g:session_path = '~/.vim/sessions' (default)

Weather to auto save the current session before exiting Vim:

    let g:session_save_on_exit = 0 (default)

To save the last session name:

    set viminfo^=!

Mappings I define personally:

    nnoremap <leader>sl :SessionList<CR>
    nnoremap <leader>ss :SessionSave<CR>
    nnoremap <leader>sa :SessionSaveas<CR>
    nnoremap <leader>si :SessionInfo<CR>

## Credit
Special thanks to the original author Yuri Klubakov who made [sessionman.vim](https://github.com/vim-scripts/sessionman.vim) which this plugin is based on.
