let g:true  = 1
let g:false = 0

let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin  = has('win32unix')
let s:is_mac     = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \    (!executable('xdg-open') &&
      \    system('uname') =~? '^darwin'))
let s:is_linux   = !s:is_mac && has('unix')

function! IsWindows() abort
  return s:is_windows
endfunction

function! IsMac() abort
  return s:is_mac
endfunction

function! s:vimrc_environment()
  let env = {}

  let env.is_starting = has('vim_starting')
  let env.is_gui      = has('gui_running')
  let env.hostname    = substitute(hostname(), '[^\w.]', '', '')

  " vim
  if s:is_windows
    let vimpath = expand('~/vimfiles')
  else
    let vimpath = expand('~/.vim')
  endif

  " vim-plug
  "let plug    = vimpath . "/autoload/plug.vim"
  "let plugged = vimpath . "/plugged"
  "let env.is_plug = filereadable(plug)

  let env.path = {
        \ 'vim': vimpath,
        \ }

  let env.bin = {
        \ 'ag':        executable('ag'),
        \ 'osascript': executable('osascript'),
        \ }

  " tmux
  let env.is_tmux_running = !empty($TMUX)
  let env.tmux_proc = system('tmux display-message -p "#W"')

  "echo get(g:env.vimrc, 'enable_plugin', g:false)
  let env.vimrc = {
              \ 'plugin_on': g:true,
              \ 'suggest_neobundleinit': g:true,
              \ 'goback_to_eof2bof': g:true,
              \ 'save_window_position': g:true,
              \ 'restore_cursor_position': g:true,
              \ 'statusline_manually': g:true,
              \ 'add_execute_perm': g:true,
              \ 'colorize_statusline_insert': g:true,
              \ 'manage_rtp_manually': g:true,
              \ 'auto_cd_file_parentdir': g:true,
              \ 'ignore_all_settings': g:true,
              \ 'check_plug_update': g:true,
              \ }

  return env
endfunction

" g:env is an environment variable in vimrc
let g:env = s:vimrc_environment()

" __END__ {{{1
" vim:fdm=marker expandtab fdc=3:
