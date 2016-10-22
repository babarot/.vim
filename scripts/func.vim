if !exists('g:env')
  finish
endif

function! s:b4b4r07() "{{{1
  hide enew
  setlocal buftype=nofile nowrap nolist nonumber bufhidden=wipe
  setlocal modifiable nocursorline nocursorcolumn

  let b4b4r07 = []
  call add(b4b4r07, 'Copyright (c) 2014                                 b4b4r07''s vimrc.')
  call add(b4b4r07, '.______    _  _    .______    _  _    .______        ___    ______  ')
  call add(b4b4r07, '|   _  \  | || |   |   _  \  | || |   |   _  \      / _ \  |____  | ')
  call add(b4b4r07, '|  |_)  | | || |_  |  |_)  | | || |_  |  |_)  |    | | | |     / /  ')
  call add(b4b4r07, '|   _  <  |__   _| |   _  <  |__   _| |      /     | | | |    / /   ')
  call add(b4b4r07, '|  |_)  |    | |   |  |_)  |    | |   |  |\  \----.| |_| |   / /    ')
  call add(b4b4r07, '|______/     |_|   |______/     |_|   | _| `._____| \___/   /_/     ')
  call add(b4b4r07, '           #VIM + #ZSH + #TMUX = Best Developer Environmen          ')

  silent put =repeat([''], winheight(0)/2 - len(b4b4r07)/2)
  let space = repeat(' ', winwidth(0)/2 - strlen(b4b4r07[0])/2)
  for line in b4b4r07
    put =space . line
  endfor
  silent put =repeat([''], winheight(0)/2 - len(b4b4r07)/2 + 1)
  silent file B4B4R07
  1

  execute 'syntax match Directory display ' . '"'. '^\s\+\U\+$'. '"'
  setlocal nomodifiable
  redraw
  let char = getchar()
  silent enew
  call feedkeys(type(char) == type(0) ? nr2char(char) : char)
endfunction
augroup vimrc-without-plugin
  autocmd!
  autocmd VimEnter * if !argc() | call <SID>b4b4r07() | endif
augroup END

"function! s:cd_file_parentdir() "{{{1
"  execute ":lcd " . expand("%:p:h")
"endfunction
"command! Cdcd call <SID>cd_file_parentdir()
"
""if g:env.vimrc.auto_cd_file_parentdir == g:true
"augroup cd-file-parentdir
"  autocmd!
"  autocmd BufRead,BufEnter * if g:env.vimrc.auto_cd_file_parentdir == g:true | call <SID>cd_file_parentdir() | endif
"augroup END
""endif

command! -nargs=? -complete=dir -bang CD call s:change_current_dir('<args>', '<bang>')
function! s:change_current_dir(directory, bang)
    if a:directory == ''
        lcd %:p:h
    else
        execute 'lcd' . expand(a:directory)
    endif
    if a:bang == ''
        redraw
        call s:ls('', '')
    endif
endfunction

if g:env.vimrc.auto_cd_file_parentdir == g:true
    augroup cd-file-parentdir
        autocmd!
        autocmd BufEnter * call <SID>change_current_dir('', '!')
    augroup END
endif

function! s:get_buflists(...) "{{{1
  if a:0 && a:1 ==# 'n'
    silent bnext
  elseif a:0 && a:1 ==# 'p'
    silent bprev
  endif

  let list  = ''
  let lists = []
  for buf in range(1, bufnr('$'))
    if bufexists(buf) && buflisted(buf)
      let list  = bufnr(buf) . "#" . fnamemodify(bufname(buf), ':t')
      let list .= getbufvar(buf, "&modified") ? '+' : ''
      if bufnr('%') ==# buf
        let list = "[" . list . "]"
      else
        let list = " " . list . " "
      endif
      call add(lists, list)
    endif
  endfor
  redraw | echo join(lists, "")
endfunction
if g:plug.is_installed('vim-buftabs')
  nnoremap <silent> <C-j> :<C-u>silent bnext<CR>
  nnoremap <silent> <C-k> :<C-u>silent bprev<CR>
else
  nnoremap <silent> <C-j> :<C-u>silent bnext<CR>:<C-u>call <SID>get_buflists()<CR>
  nnoremap <silent> <C-k> :<C-u>silent bprev<CR>:<C-u>call <SID>get_buflists()<CR>
endif

function! s:smart_foldcloser() "{{{1
  if foldlevel('.') == 0
    normal! zM
    return
  endif

  let foldc_lnum = foldclosed('.')
  normal! zc
  if foldc_lnum == -1
    return
  endif

  if foldclosed('.') != foldc_lnum
    return
  endif
  normal! zM
endfunction
nnoremap <silent> <C-_> :<C-u>call <SID>smart_foldcloser()<CR>

function! s:win_tab_switcher(...) "{{{1
  let minus = 0
  if &laststatus == 1 && winnr('$') != 1
    let minus += 1
  elseif &laststatus == 2
    let minus += 1
  endif
  let minus += &cmdheight
  if &showtabline == 1 && tabpagenr('$') != 1
    let minus += 1
  elseif &showtabline == 2
    let minus += 1
  endif

  let is_split   = winheight(0) != &lines - minus
  let is_vsplit  = winwidth(0)  != &columns
  let is_tabpage = tabpagenr('$') >= 2

  let buffer_switcher = get(g:, 'buffer_switcher', 0)
  if a:0 && a:1 ==# 'l'
    if is_tabpage
      if tabpagenr() == tabpagenr('$')
        if !is_split && !is_vsplit
          if buffer_switcher
            silent bnext
          else
            echohl WarningMsg
            echo 'Last tabpages'
            echohl None
          endif
        endif
        if (is_split || is_vsplit) && winnr() == winnr('$')
          if buffer_switcher
            silent bnext
          else
            echohl WarningMsg
            echo 'Last tabpages'
            echohl None
          endif
        elseif (is_split || is_vsplit) && winnr() != winnr('$')
          silent wincmd w
        endif
      else
        if !is_split && !is_vsplit
          silent tabnext
        endif
        if (is_split || is_vsplit) && winnr() == winnr('$')
          silent tabnext
        elseif (is_split || is_vsplit) && winnr() != winnr('$')
          silent wincmd w
        endif
      endif
    else
      if !is_split && !is_vsplit
        if buffer_switcher
          silent bnext
        else
          echohl WarningMsg
          echo 'Last tabpages'
          echohl None
        endif
      endif
      if (is_split || is_vsplit) && winnr() == winnr('$')
        if buffer_switcher
          silent bnext
        else
          echohl WarningMsg
          echo 'Last tabpages'
          echohl None
        endif
      else
        silent wincmd w
      endif
    endif
  endif
  if a:0 && a:1 ==# 'h'
    if is_tabpage
      if tabpagenr() == 1
        if !is_split && !is_vsplit
          if buffer_switcher
            silent bprevious
          else
            echohl WarningMsg
            echo 'First tabpages'
            echohl None
          endif
        endif
        if (is_split || is_vsplit) && winnr() == 1
          if buffer_switcher
            silent bprevious
          else
            echohl WarningMsg
            echo 'First tabpages'
            echohl None
          endif
        elseif (is_split || is_vsplit) && winnr() != 1
          silent wincmd W
        endif
      else
        if !is_split && !is_vsplit
          silent tabprevious
        endif
        if (is_split || is_vsplit) && winnr() == 1
          silent tabprevious
        elseif (is_split || is_vsplit) && winnr() != 1
          silent wincmd W
        endif
      endif
    else
      if !is_split && !is_vsplit
        if buffer_switcher
          silent bprevious
        else
          echohl WarningMsg
          echo 'First tabpages'
          echohl None
        endif
      endif
      if (is_split || is_vsplit) && winnr() == 1
        if buffer_switcher
          silent bprevious
        else
          echohl WarningMsg
          echo 'First tabpages'
          echohl None
        endif
      else
        silent wincmd W
      endif
    endif
  endif

  if g:plug.is_installed("vim-buftabs")
  else
    redraw
    call <SID>get_buflists()
  endif
endfunction
"nnoremap <silent> <C-l> :<C-u>call <SID>win_tab_switcher('l')<CR>
"nnoremap <silent> <C-h> :<C-u>call <SID>win_tab_switcher('h')<CR>

function! s:root() "{{{1
  let me = expand('%:p:h')
  let gitd = finddir('.git', me.';')
  if empty(gitd)
    echo "Not in git repo"
  else
    let gitp = fnamemodify(gitd, ':h')
    echo "Change directory to: ".gitp
    execute 'lcd' gitp
  endif
endfunction
command! Root call <SID>root()

" Restore cursor position {{{1
if g:env.vimrc.restore_cursor_position == g:true
  function! s:restore_cursor_postion()
    if line("'\"") <= line("$")
      normal! g`"
      return 1
    endif
  endfunction
  augroup restore-cursor-position
    autocmd!
    autocmd BufWinEnter * call <SID>restore_cursor_postion()
  augroup END
endif

" Backup automatically {{{1
if IsWindows()
  set nobackup
else
  set backup
  call Mkdir('~/.vim/backup')
  augroup backup-files-automatically
    autocmd!
    autocmd BufWritePre * call s:backup_files()
  augroup END

  function! s:backup_files()
    let dir = strftime("~/.backup/vim/%Y/%m/%d", localtime())
    if !isdirectory(dir)
      call system("mkdir -p " . dir)
      call system("chown goth:staff " . dir)
    endif
    execute "set backupdir=" . dir
    execute "set backupext=." . strftime("%H_%M_%S", localtime())
  endfunction
endif

function! s:get_buflists(...) "{{{
  if a:0 && a:1 ==# 'n'
    silent bnext
  elseif a:0 && a:1 ==# 'p'
    silent bprev
  endif

  let list  = ''
  let lists = []
  for buf in range(1, bufnr('$'))
    if bufexists(buf) && buflisted(buf)
      let list  = bufnr(buf) . "#" . fnamemodify(bufname(buf), ':t')
      let list .= getbufvar(buf, "&modified") ? '+' : ''
      if bufnr('%') ==# buf
        let list = "[" . list . "]"
      else
        let list = " " . list . " "
      endif
      call add(lists, list)
    endif
  endfor
  redraw | echo join(lists, "")
endfunction

function! s:win_tab_switcher(...) "{{{
  let minus = 0
  if &laststatus == 1 && winnr('$') != 1
    let minus += 1
  elseif &laststatus == 2
    let minus += 1
  endif
  let minus += &cmdheight
  if &showtabline == 1 && tabpagenr('$') != 1
    let minus += 1
  elseif &showtabline == 2
    let minus += 1
  endif

  let is_split   = winheight(0) != &lines - minus
  let is_vsplit  = winwidth(0)  != &columns
  let is_tabpage = tabpagenr('$') >= 2

  let buffer_switcher = get(g:, 'buffer_switcher', 0)
  if a:0 && a:1 ==# 'l'
    if is_tabpage
      if tabpagenr() == tabpagenr('$')
        if !is_split && !is_vsplit
          if buffer_switcher
            silent bnext
          else
            echohl WarningMsg
            echo 'Last tabpages'
            echohl None
          endif
        endif
        if (is_split || is_vsplit) && winnr() == winnr('$')
          if buffer_switcher
            silent bnext
          else
            echohl WarningMsg
            echo 'Last tabpages'
            echohl None
          endif
        elseif (is_split || is_vsplit) && winnr() != winnr('$')
          silent wincmd w
        endif
      else
        if !is_split && !is_vsplit
          silent tabnext
        endif
        if (is_split || is_vsplit) && winnr() == winnr('$')
          silent tabnext
        elseif (is_split || is_vsplit) && winnr() != winnr('$')
          silent wincmd w
        endif
      endif
    else
      if !is_split && !is_vsplit
        if buffer_switcher
          silent bnext
        else
          echohl WarningMsg
          echo 'Last tabpages'
          echohl None
        endif
      endif
      if (is_split || is_vsplit) && winnr() == winnr('$')
        if buffer_switcher
          silent bnext
        else
          echohl WarningMsg
          echo 'Last tabpages'
          echohl None
        endif
      else
        silent wincmd w
      endif
    endif
  endif
  if a:0 && a:1 ==# 'h'
    if is_tabpage
      if tabpagenr() == 1
        if !is_split && !is_vsplit
          if buffer_switcher
            silent bprevious
          else
            echohl WarningMsg
            echo 'First tabpages'
            echohl None
          endif
        endif
        if (is_split || is_vsplit) && winnr() == 1
          if buffer_switcher
            silent bprevious
          else
            echohl WarningMsg
            echo 'First tabpages'
            echohl None
          endif
        elseif (is_split || is_vsplit) && winnr() != 1
          silent wincmd W
        endif
      else
        if !is_split && !is_vsplit
          silent tabprevious
        endif
        if (is_split || is_vsplit) && winnr() == 1
          silent tabprevious
        elseif (is_split || is_vsplit) && winnr() != 1
          silent wincmd W
        endif
      endif
    else
      if !is_split && !is_vsplit
        if buffer_switcher
          silent bprevious
        else
          echohl WarningMsg
          echo 'First tabpages'
          echohl None
        endif
      endif
      if (is_split || is_vsplit) && winnr() == 1
        if buffer_switcher
          silent bprevious
        else
          echohl WarningMsg
          echo 'First tabpages'
          echohl None
        endif
      else
        silent wincmd W
      endif
    endif
  endif

  if g:plug.is_installed('vim-buftabs')
  else
    redraw
    call <SID>get_buflists()
  endif
endfunction

nnoremap <silent> <C-l> :<C-u>call <SID>win_tab_switcher('l')<CR>
nnoremap <silent> <C-h> :<C-u>call <SID>win_tab_switcher('h')<CR>

" __END__ {{{1
" vim:fdm=marker expandtab fdc=3:
