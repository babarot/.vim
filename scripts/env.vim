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
        \ 'vim':     vimpath,
        \ }

  let env.bin = {
        \ 'ag':        executable('ag'),
        \ 'osascript': executable('osascript'),
        \ }

  " tmux
  let env.is_tmux_running = !empty($TMUX)
  let env.tmux_proc = system('tmux display-message -p "#W"')

  return env
endfunction

" g:env is an environment variable in vimrc
let g:env   = s:vimrc_environment()
let g:true  = 1
let g:false = 0

" vimrc management variables
let g:vimrc_plugin_on                  = get(g:, 'vimrc_plugin_on',                  g:true)
let g:vimrc_suggest_neobundleinit      = get(g:, 'vimrc_suggest_neobundleinit',      g:true)
let g:vimrc_goback_to_eof2bof          = get(g:, 'vimrc_goback_to_eof2bof',          g:false)
let g:vimrc_save_window_position       = get(g:, 'vimrc_save_window_position',       g:false)
let g:vimrc_restore_cursor_position    = get(g:, 'vimrc_restore_cursor_position',    g:true)
let g:vimrc_statusline_manually        = get(g:, 'vimrc_statusline_manually',        g:true)
let g:vimrc_add_execute_perm           = get(g:, 'vimrc_add_execute_perm',           g:false)
let g:vimrc_colorize_statusline_insert = get(g:, 'vimrc_colorize_statusline_insert', g:true)
let g:vimrc_manage_rtp_manually        = get(g:, 'g:vimrc_manage_rtp_manually',      g:false)
let g:vimrc_auto_cd_file_parentdir     = get(g:, 'g:vimrc_auto_cd_file_parentdir',   g:true)
let g:vimrc_ignore_all_settings        = get(g:, 'g:vimrc_ignore_all_settings',      g:false)
let g:vimrc_check_plug_update          = get(g:, 'g:vimrc_check_plug_update',        g:true)

" if g:vimrc_manage_rtp_manually is g:true, g:vimrc_plugin_on is disabled.
let g:vimrc_plugin_on = g:vimrc_manage_rtp_manually == g:true ? g:false : g:vimrc_plugin_on

" __END__ {{{1
" vim:fdm=marker expandtab fdc=3:
