" Tiny vim
if 0 | endif

" Use plain vim
" when vim was invoked by 'sudo' command
" or, invoked as 'git difftool'
if exists('$SUDO_USER') || exists('$GIT_DIR')
  finish
endif

if &compatible
  set nocompatible
endif

function! s:load(path, ...) abort
  let abspath = resolve(expand('~/.vim/scripts/' . a:path))
  if filereadable(abspath)
    execute 'source' fnameescape(abspath)
  else
    echo abspath . 'is not'
    return
  endif
endfunction

" Set augroup.
augroup MyAutoCmd
  autocmd!
augroup END

call s:load('env.vim')

if g:env.is_starting
  " Necesary for lots of cool vim things
  "set nocompatible
  " http://rbtnn.hateblo.jp/entry/2014/11/30/174749

  " Define the entire vimrc encoding
  scriptencoding utf-8
  " Initialize runtimepath
  set runtimepath&

  " Check if there are plugins not to be installed
  augroup vimrc-check-plug
    autocmd!
    if g:vimrc_check_plug_update == g:true
      autocmd VimEnter * if !argc() | call g:p.check_installation() | endif
    endif
  augroup END

  " Vim starting time
  if has('reltime') "&& !exists('g:pluginit')
    let g:startuptime = reltime()
    augroup vimrc-startuptime
      autocmd!
      autocmd VimEnter * let g:startuptime = reltime(g:startuptime) | redraw
            \ | echomsg 'startuptime: ' . reltimestr(g:startuptime)
    augroup END
  endif
endif

call s:load('plug.vim')
"call s:load('dein.vim')
call s:load('functions.vim')
call s:load('base.vim')
call s:load('options.vim')
call s:load('appearance.vim')
call s:load('mappings.vim')
call s:load('commands.vim')
call s:load('plugins.vim')
call s:load('gui.vim')
call s:load('func.vim')

" Must be written at the last.  see :help 'secure'.
set secure

" vi:set ts=2 sw=2 sts=2:
" vim:fdt=substitute(getline(v\:foldstart),'\\(.\*\\){\\{3}','\\1',''):
" vim:fdm=marker expandtab fdc=3:
