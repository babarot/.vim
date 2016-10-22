finish

" func s:toggle_option() {{{2
function! s:toggle_option(option_name)
  if exists('&' . a:option_name)
    execute 'setlocal' a:option_name . '!'
    execute 'setlocal' a:option_name . '?'
  endif
endfunction

" func s:toggle_variable() {{{2
function! s:toggle_variable(variable_name)
  if eval(a:variable_name)
    execute 'let' a:variable_name . ' = 0'
  else
    execute 'let' a:variable_name . ' = 1'
  endif
  echo printf('%s = %s', a:variable_name, eval(a:variable_name))
endfunction


" func s:ls() {{{2
function! s:ls(path, bang)
  let path = empty(a:path) ? getcwd() : expand(a:path)
  if filereadable(path)
    if executable("ls")
      echo system("ls -l " . path)
      return v:shell_error ? s:false : s:true
    else
      return s:error('ls: command not found')
    endif
  endif

  if !isdirectory(path)
    return s:error(path.":No such file or directory")
  endif

  let save_ignore = &wildignore
  set wildignore=
  let filelist = glob(path . "/*")
  if !empty(a:bang)
    let filelist .= "\n".glob(path . "/.*[^.]")
  endif
  let &wildignore = save_ignore
  let filelist = substitute(filelist, '', '^M', 'g')

  if empty(filelist)
    return s:error("no file")
  endif

  let lists = []
  for file in split(filelist, "\n")
    if isdirectory(file)
      call add(lists, fnamemodify(file, ":t") . "/")
    else
      if executable(file)
        call add(lists, fnamemodify(file, ":t") . "*")
      elseif getftype(file) == 'link'
        call add(lists, fnamemodify(file, ":t") . "@")
      else
        call add(lists, fnamemodify(file, ":t"))
      endif
    endif
  endfor

  echohl WarningMsg | echon len(lists) . ":\t" | echohl None
  highlight LsDirectory  cterm=bold ctermfg=NONE ctermfg=26        gui=bold guifg=#0096FF   guibg=NONE
  highlight LsExecutable cterm=NONE ctermfg=NONE ctermfg=Green     gui=NONE guifg=Green     guibg=NONE
  highlight LsSymbolick  cterm=NONE ctermfg=NONE ctermfg=LightBlue gui=NONE guifg=LightBlue guibg=NONE

  for item in lists
    if item =~ '/'
      echohl LsDirectory | echon item[:-2] | echohl NONE
      echon item[-1:-1] . " "
    elseif item =~ '*'
      echohl LsExecutable | echon item[:-2] | echohl NONE
      echon item[-1:-1] . " "
    elseif item =~ '@'
      echohl LsSymbolick | echon item[:-2] | echohl NONE
      echon item[-1:-1] . " "
    else
      echon item . " "
    endif
  endfor

  return s:true
endfunction

" func s:count_buffers() {{{2
function! s:count_buffers()
  let l:count = 0
  for i in range(1, bufnr('$'))
    if bufexists(i) && buflisted(i)
      let l:count += 1
    endif
  endfor
  return l:count
endfunction

" func s:get_buflists() {{{2
function! s:get_buflists(...)
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

" func s:smart_bwipeout() {{{2
function! s:smart_bwipeout(mode)
  " Bwipeout! all buffers except current buffer.
  if a:mode == 1
    for i in range(1, bufnr('$'))
      if bufexists(i)
        if bufnr('%') ==# i | continue | endif
        execute 'silent bwipeout! ' . i
      endif
    endfor
    return
  endif

  if a:mode == 0
    if winnr('$') != 1
      quit
      return
    elseif tabpagenr('$') != 1
      tabclose
      return
    endif
  endif

  let bufname = empty(bufname(bufnr('%'))) ? bufnr('%') . "#" : bufname(bufnr('%'))
  if &modified == 1
    echo printf("'%s' is unsaved. Quit!? [y(f)/N/w] ", bufname)
    let c = nr2char(getchar())

    if c ==? 'w'
      let filename = ''
      if bufname(bufnr("%")) ==# filename
        redraw
        while empty(filename)
          let filename = input('Tell me filename: ')
        endwhile
      endif
      execute "write " . filename
      silent bwipeout!

    elseif c ==? 'y' || c ==? 'f'
      silent bwipeout!
    else
      redraw
      echo "Do nothing"
      return
    endif
  else
    silent bwipeout
  endif

  if s:has_plugin("vim-buftabs")
    echo "Bwipeout " . bufname
  else
    redraw
    call <SID>get_buflists()
  endif
endfunction

" func s:smart_bchange() {{{2
function! s:smart_bchange(mode)
  let mode = a:mode

  " If window splitted, no working
  if winnr('$') != 1
    " Normal bnext/bprev
    execute 'silent' mode ==? 'n' ? 'bnext' : 'bprevious'
    if exists("*s:get_buflists") && exists("*s:count_buffers")
      if s:count_buffers() > 1
        call s:get_buflists()
      endif
    endif
    return
  endif

  " Get all buffer numbers in tabpages
  let tablist = []
  for i in range(tabpagenr('$'))
    call add(tablist, tabpagebuflist(i + 1))
  endfor

  " Get buffer number
  execute 'silent' mode ==? 'n' ? 'bnext' : 'bprevious'
  let bufnr = bufnr('%')
  execute 'silent' mode ==? 'n' ? 'bprevious' : 'bnext'

  " Check next/prev buffer number if exists in l:tablist
  let nextbuf = []
  call add(nextbuf, bufnr)
  if index(tablist, nextbuf) >= 0
    execute 'silent tabnext' index(tablist, nextbuf) + 1
  else
    " Normal bnext/bprev
    execute 'silent' mode ==? 'n' ? 'bnext' : 'bprevious'
  endif
endfunction

function! s:bufnew(buf, bang)
  let buf = empty(a:buf) ? '' : a:buf
  execute "new" buf | only
  if !empty(a:bang)
    let bufname = empty(buf) ? '[Scratch]' : buf
    setlocal bufhidden=unload
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal noswapfile
    silent file `=bufname`
  endif
endfunction

" func s:buf_enqueue() {{{2
function! s:buf_enqueue(buf)
  let buf = fnamemodify(a:buf, ':p')
  if bufexists(buf) && buflisted(buf) && filereadable(buf)
    let idx = match(s:bufqueue ,buf)
    if idx != -1
      call remove(s:bufqueue, idx)
    endif
    call add(s:bufqueue, buf)
  endif
endfunction

" func s:buf_dequeue() {{{2
function! s:buf_dequeue(buf)
  if empty(s:bufqueue)
    throw 'bufqueue: Empty queue.'
  endif

  if a:buf =~# '\d\+'
    return remove(s:bufqueue, a:buf)
  else
    return remove(s:bufqueue, index(s:bufqueue, a:buf))
  endif
endfunction

" func s:buf_restore() {{{2
function! s:buf_restore()
  try
    execute 'edit' s:buf_dequeue(-1)
  catch /^bufqueue:/
    "echohl ErrorMsg
    "echomsg v:exception
    "echohl None
    call s:error(v:exception)
  endtry
endfunction

" func s:all_buffers_bwipeout() {{{2
function! s:all_buffers_bwipeout()
  for i in range(1, bufnr('$'))
    if bufexists(i) && buflisted(i)
      execute 'bwipeout' i
    endif
  endfor
endfunction

" func s:win_tab_switcher() {{{2
function! s:win_tab_switcher(...)
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

  if s:has_plugin("vim-buftabs")
  else
    redraw
    call <SID>get_buflists()
  endif
endfunction

" func s:tabdrop() {{{2
function! s:tabdrop(target)
  let target = empty(a:target) ? expand('%:p') : bufname(a:target + 0)
  if !empty(target) && bufexists(target) && buflisted(target)
    execute 'tabedit' target
  else
    call s:warning("Could not tabedit")
  endif
endfunction

" func s:tabnew() {{{2
function! s:tabnew(num)
  let num = empty(a:num) ? 1 : a:num
  for i in range(1, num)
    tabnew
  endfor
endfunction

" func s:move_tabpage() {{{2
function! s:move_tabpage(dir)
  if a:dir == "right"
    let num = tabpagenr()
  elseif a:dir == "left"
    let num = tabpagenr() - 2
  endif
  if num >= 0
    execute "tabmove" num
  endif
endfunction

" func s:close_all_right_tabpages() {{{2
function! s:close_all_right_tabpages()
  let current_tabnr = tabpagenr()
  let last_tabnr = tabpagenr("$")
  let num_close = last_tabnr - current_tabnr
  let i = 0
  while i < num_close
    execute "tabclose " . (current_tabnr + 1)
    let i = i + 1
  endwhile
endfunction

" func s:close_all_left_tabpages() {{{2
function! s:close_all_left_tabpages()
  let current_tabnr = tabpagenr()
  let num_close = current_tabnr - 1
  let i = 0
  while i < num_close
    execute "tabclose 1"
    let i = i + 1
  endwhile
endfunction

" func s:find_tabnr() {{{2
function! s:find_tabnr(bufnr)
  for tabnr in range(1, tabpagenr("$"))
    if index(tabpagebuflist(tabnr), a:bufnr) !=# -1
      return tabnr
    endif
  endfor
  return -1
endfunction

" func s:find_winnr() {{{2
function! s:find_winnr(bufnr)
  for winnr in range(1, winnr("$"))
    if a:bufnr ==# winbufnr(winnr)
      return winnr
    endif
  endfor
  return 1
endfunction

" func s:find_winnr() {{{2
function! s:recycle_open(default_open, path)
  let default_action = a:default_open . ' ' . a:path
  if bufexists(a:path)
    let bufnr = bufnr(a:path)
    let tabnr = s:find_tabnr(bufnr)
    if tabnr ==# -1
      execute default_action
      return
    endif
    execute 'tabnext ' . tabnr
    let winnr = s:find_winnr(bufnr)
    execute winnr . 'wincmd w'
  else
    execute default_action
  endif
endfunction



"}}}
" Add execute permission {{{2
if s:vimrc_add_execute_perm == s:true
  if executable('chmod')
    augroup auto-add-executable
      autocmd!
      autocmd BufWritePost * call <SID>add_permission_x()
    augroup END

    function! s:add_permission_x()
      let file = expand('%:p')
      if !executable(file)
        if getline(1) =~# '^#!'
              \ || &filetype =~ "\\(z\\|c\\|ba\\)\\?sh$"
              \ && input(printf('"%s" is not perm 755. Change mode? [y/N] ', expand('%:t'))) =~? '^y\%[es]$'
          call system("chmod 755 " . shellescape(file))
          redraw | echo "Set permission 755!"
        endif
      endif
    endfunction
  endif
endif

" Restore cursor position {{{2
if s:vimrc_restore_cursor_position == s:true
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

" Restore the buffer that has been deleted {{{2
let s:bufqueue = []
augroup buffer-queue-restore
  autocmd!
  autocmd BufDelete * call <SID>buf_enqueue(expand('#'))
augroup END

" Automatically get buffer list {{{2
if !s:has_plugin('vim-buftabs')
  augroup bufenter-get-buffer-list
    autocmd!
    " Escape getting buflist by "@% != ''" when "VimEnter"
    autocmd BufEnter,BufAdd,BufWinEnter * if @% != '' | call <SID>get_buflists() | endif
  augroup END
endif

" Automatically cd parent directory when opening the file {{{2
function! s:cd_file_parentdir()
  execute ":lcd " . expand("%:p:h")
endfunction
command! Cdcd call <SID>cd_file_parentdir()
nnoremap Q :<C-u>call <SID>cd_file_parentdir()<CR>

if s:vimrc_auto_cd_file_parentdir == s:true
  augroup cd-file-parentdir
    autocmd!
    autocmd BufRead,BufEnter * call <SID>cd_file_parentdir()
  augroup END
endif

" QuickLook for mac {{{2
if s:is_mac && executable("qlmanage")
  command! -nargs=? -complete=file QuickLook call s:quicklook(<f-args>)
  function! s:quicklook(...)
    let file = a:0 ? expand(a:1) : expand('%:p')
    if !s:has(file)
      echo printf('%s: No such file or directory', file)
      return 0
    endif
    call system(printf('qlmanage -p %s >& /dev/null', shellescape(file)))
  endfunction
endif

" Backup automatically {{{2
if s:is_windows
  set nobackup
else
  set backup
  call s:mkdir('~/.vim/backup')
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

" Swap settings {{{2
call s:mkdir('~/.vim/swap')
set noswapfile
set directory=~/.vim/swap

" Some utilities. {{{2


" Measure fighting strength of Vim.
command! -bar -bang -nargs=? -complete=file Scouter echo Scouter(empty(<q-args>) ? $MYVIMRC : expand(<q-args>), <bang>0)

" Ls like a shell-ls
command! -nargs=? -bang -complete=file Ls call s:ls(<q-args>, <q-bang>)

" Show all runtimepaths.
command! -bar RTP echo substitute(&runtimepath, ',', "\n", 'g')

" View all mappings
command! -nargs=* -complete=mapping AllMaps map <args> | map! <args> | lmap <args>

" Handle buffers {{{2
" Wipeout all buffers
command! -nargs=0 AllBwipeout call s:all_buffers_bwipeout()

" Get buffer queue list for restore
command! -nargs=0 BufQueue echo len(s:bufqueue)
      \ ? reverse(split(substitute(join(s:bufqueue, ' '), $HOME, '~', 'g')))
      \ : "No buffers in 's:bufqueue'."

" Get buffer list like ':ls'
command! -nargs=0 BufList call s:get_buflists()

" Smart bnext/bprev
command! Bnext call s:smart_bchange('n')
command! Bprev call s:smart_bchange('p')

" Show buffer kind.
command! -bar EchoBufKind setlocal bufhidden? buftype? swapfile? buflisted?

" Open new buffer or scratch buffer with bang.
command! -bang -nargs=? -complete=file BufNew call <SID>bufnew(<q-args>, <q-bang>)

" Bwipeout(!) for all-purpose.
command! -nargs=0 -bang Bwipeout call <SID>smart_bwipeout(0, <q-bang>)


" Handle tabpages {{{2
" Make tabpages
command! -nargs=? TabNew call s:tabnew(<q-args>)

"Open again with tabpages
command! -nargs=? Tab call s:tabdrop(<q-args>)

" Open the buffer again with tabpages
command! -nargs=? -complete=buffer ROT call <SID>recycle_open('tabedit', empty(<q-args>) ? expand('#') : expand(<q-args>))

" Handle files {{{2
" Open a file.
" Remove blank line
command! RemoveBlankLine silent! global/^$/delete | nohlsearch | normal! ``


" Handle encodings  {{{2
" In particular effective when I am garbled in a terminal
command! -bang -bar -complete=file -nargs=? Utf8      edit<bang> ++enc=utf-8 <args>
command! -bang -bar -complete=file -nargs=? Iso2022jp edit<bang> ++enc=iso-2022-jp <args>
command! -bang -bar -complete=file -nargs=? Cp932     edit<bang> ++enc=cp932 <args>
command! -bang -bar -complete=file -nargs=? Euc       edit<bang> ++enc=euc-jp <args>
command! -bang -bar -complete=file -nargs=? Utf16     edit<bang> ++enc=ucs-2le <args>
command! -bang -bar -complete=file -nargs=? Utf16be   edit<bang> ++enc=ucs-2 <args>
command! -bang -bar -complete=file -nargs=? Jis       Iso2022jp<bang> <args>
command! -bang -bar -complete=file -nargs=? Sjis      Cp932<bang> <args>
command! -bang -bar -complete=file -nargs=? Unicode   Utf16<bang> <args>

" Tried to make a file note version
" Don't save it because dangerous.
command! WUtf8      setlocal fenc=utf-8
command! WIso2022jp setlocal fenc=iso-2022-jp
command! WCp932     setlocal fenc=cp932
command! WEuc       setlocal fenc=euc-jp
command! WUtf16     setlocal fenc=ucs-2le
command! WUtf16be   setlocal fenc=ucs-2
command! WJis       WIso2022jp
command! WSjis      WCp932
command! WUnicode   WUtf16

" Appoint a line feed
command! -bang -complete=file -nargs=? WUnix write<bang> ++fileformat=unix <args> | edit <args>
command! -bang -complete=file -nargs=? WDos  write<bang> ++fileformat=dos <args>  | edit <args>
command! -bang -complete=file -nargs=? WMac  write<bang> ++fileformat=mac <args>  | edit <args>

" Essentials {{{2
" It is likely to be changed by $VIM/vimrc
if has('vim_starting')
  mapclear
  mapclear!
endif

" Use backslash
if s:is_mac
  noremap ﾂ･ \
  noremap \ ﾂ･
endif

" Define mapleader
let mapleader = ','
let maplocalleader = ','

" Smart space mapping
" Notice: when starting other <Space> mappings in noremap, disappeared [Space]
nmap  <Space>   [Space]
xmap  <Space>   [Space]
nnoremap  [Space]   <Nop>
xnoremap  [Space]   <Nop>

" Function's commands {{{2
" MRU within the vimrc
if !s:has_plugin('mru.vim') 
  "if exists(':MRU2')
  if exists('*s:MRU_Create_Window')
    nnoremap <silent> [Space]j :<C-u>call <SID>MRU_Create_Window()<CR>
    "nnoremap <silent> [Space]j :<C-u>MRU<CR>
  endif
endif

" Smart folding close

" Kill buffer
if s:has_plugin('vim-buftabs')
  nnoremap <silent> <C-x>k     :<C-u>call <SID>smart_bwipeout(0)<CR>
  nnoremap <silent> <C-x>K     :<C-u>call <SID>smart_bwipeout(1)<CR>
  nnoremap <silent> <C-x><C-k> :<C-u>call <SID>smart_bwipeout(2)<CR>
else
  "autocmd BufUnload,BufLeave,BufDelete,BufWipeout * call <SID>get_buflists()

  nnoremap <silent> <C-x>k     :<C-u>call <SID>smart_bwipeout(0)<CR>
  nnoremap <silent> <C-x>K     :<C-u>call <SID>smart_bwipeout(1)<CR>
  nnoremap <silent> <C-x><C-k> :<C-u>call <SID>smart_bwipeout(2)<CR>
  "nnoremap <silent> <C-x>k     :<C-u>silent call <SID>smart_bwipeout(0)<CR>:<C-u>call <SID>get_buflists()<CR>
  "nnoremap <silent> <C-x>K     :<C-u>silent call <SID>smart_bwipeout(1)<CR>:<C-u>call <SID>get_buflists()<CR>
  "nnoremap <silent> <C-x><C-k> :<C-u>silent call <SID>smart_bwipeout(2)<CR>:<C-u>call <SID>get_buflists()<CR>
endif

" Restore buffers
nnoremap <silent> <C-x>u :<C-u>call <SID>buf_restore()<CR>

" Tabpages mappings
nnoremap <silent> <C-t>L  :<C-u>call <SID>move_tabpage("right")<CR>
nnoremap <silent> <C-t>H  :<C-u>call <SID>move_tabpage("left")<CR>
nnoremap <silent> <C-t>dh :<C-u>call <SID>close_all_left_tabpages()<CR>
nnoremap <silent> <C-t>dl :<C-u>call <SID>close_all_right_tabpages()<CR>

" Open vimrc with tab
nnoremap <silent> [Space]. :call <SID>recycle_open('edit', $MYVIMRC)<CR>

" Easy typing tilda insted of backslash
cnoremap <expr> <Bslash> HomedirOrBackslash()

" Swap semicolon for colon {{{2
nnoremap ; :
vnoremap ; :
nnoremap q; q:
vnoremap q; q:
nnoremap : ;
vnoremap : ;

" Make less complex to escaping {{{2
inoremap jj <ESC>
cnoremap <expr> j getcmdline()[getcmdpos()-2] ==# 'j' ? "\<BS>\<C-c>" : 'j'
vnoremap <C-j><C-j> <ESC>
onoremap jj <ESC>
inoremap j[Space] j
onoremap j[Space] j

" Swap jk for gjgk {{{2
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk
nnoremap gj j
nnoremap gk k
vnoremap gj j
vnoremap gk k

if s:vimrc_goback_to_eof2bof == s:true
  function! s:up(key)
    if line(".") == 1
      return ":call cursor(line('$'), col('.'))\<CR>"
    else
      return a:key
    endif
  endfunction 
  function! s:down(key)
    if line(".") == line("$")
      return ":call cursor(1, col('.'))\<CR>"
    else
      return a:key
    endif
  endfunction
  nnoremap <expr><silent> k <SID>up("gk")
  nnoremap <expr><silent> j <SID>down("gj")
endif

" Buffers, windows, and tabpages {{{2
"nnoremap <silent> <C-j> :<C-u>call <SID>get_buflists('n')<CR>
"nnoremap <silent> <C-k> :<C-u>call <SID>get_buflists('p')<CR>
if s:has_plugin('vim-buftabs')
  nnoremap <silent> <C-j> :<C-u>silent bnext<CR>
  nnoremap <silent> <C-k> :<C-u>silent bprev<CR>
else
  nnoremap <silent> <C-j> :<C-u>silent bnext<CR>:<C-u>call <SID>get_buflists()<CR>
  nnoremap <silent> <C-k> :<C-u>silent bprev<CR>:<C-u>call <SID>get_buflists()<CR>
endif

" Windows
nnoremap s <Nop>
nnoremap sp :<C-u>split<CR>
nnoremap vs :<C-u>vsplit<CR>

function! s:vsplit_or_wincmdw()
  if winnr('$') == 1
    return ":vsplit\<CR>"
  else
    return ":wincmd w\<CR>"
  endif
endfunction
nnoremap <expr><silent> ss <SID>vsplit_or_wincmdw()
nnoremap sj <C-w>j
nnoremap sk <C-w>k
nnoremap sl <C-w>l
nnoremap sh <C-w>h

" tabpages
"nnoremap <silent> <C-l> :<C-u>silent! tabnext<CR>
"nnoremap <silent> <C-h> :<C-u>silent! tabprev<CR>
nnoremap <silent> <C-l> :<C-u>call <SID>win_tab_switcher('l')<CR>
nnoremap <silent> <C-h> :<C-u>call <SID>win_tab_switcher('h')<CR>
nnoremap t <Nop>
nnoremap <silent> [Space]t :<C-u>tabclose<CR>:<C-u>tabnew<CR>
nnoremap <silent> tt :<C-u>tabnew<CR>
nnoremap <silent> tT :<C-u>tabnew<CR>:<C-u>tabprev<CR>
nnoremap <silent> tc :<C-u>tabclose<CR>
nnoremap <silent> to :<C-u>tabonly<CR>

" Inser matching bracket automatically {{{2
if s:has_plugin("lexima.vim")
  inoremap [ []<LEFT>
  inoremap ( ()<LEFT>
  inoremap " ""<LEFT>
  inoremap ' ''<LEFT>
  inoremap ` ``<LEFT>
endif

" Make cursor-moving useful {{{2
inoremap <C-h> <Backspace>
inoremap <C-d> <Delete>

cnoremap <C-k> <UP>
cnoremap <C-j> <DOWN>
cnoremap <C-l> <RIGHT>
cnoremap <C-h> <LEFT>
cnoremap <C-d> <DELETE>
cnoremap <C-p> <UP>
cnoremap <C-n> <DOWN>
cnoremap <C-f> <RIGHT>
cnoremap <C-b> <LEFT>
cnoremap <C-a> <HOME>
cnoremap <C-e> <END>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Del>
cnoremap <C-h> <BS>

"nnoremap + <C-a>
"nnoremap - <C-x>

" Nop features {{{2
nnoremap q: <Nop>
nnoremap q/ <Nop>
nnoremap q? <Nop>
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" Folding (see :h usr_28.txt){{{2
"nnoremap <expr>l foldclosed('.') != -1 ? 'zo' : 'l'
"nnoremap <expr>h col('.') == 1 && foldlevel(line('.')) > 0 ? 'zc' : 'h'
nnoremap <silent>z0 :<C-u>set foldlevel=<C-r>=foldlevel('.')<CR><CR>

" Misc mappings {{{2
cnoreabbrev w!! w !sudo tee > /dev/null %
" CursorLine
nnoremap <silent> <Leader>l :<C-u>call <SID>toggle_option('cursorline')<CR>

nnoremap <silent> <Leader>c :<C-u>call <SID>toggle_option('cursorcolumn')<CR>

" Add a relative number toggle
nnoremap <silent> <Leader>r :<C-u>call <SID>toggle_option('relativenumber')<CR>

" Add a spell check toggle
nnoremap <silent> <Leader>s :<C-u>call <SID>toggle_option('spell')<CR>

" Tabs Increase
nnoremap <silent> ~ :let &tabstop = (&tabstop * 2 > 16) ? 2 : &tabstop * 2<CR>:echo 'tabstop:' &tabstop<CR>

" Toggle top/center/bottom
noremap <expr> zz (winline() == (winheight(0)+1)/ 2) ?  'zt' : (winline() == 1)? 'zb' : 'zz'

" Reset highlight searching
nnoremap <silent> <ESC><ESC> :nohlsearch<CR>

" key map ^,$ to <Space>h,l. Because ^ and $ is difficult to type and damage little finger!!!
noremap [Space]h ^
noremap [Space]l $

" Type 'v', select end of line in visual mode
vnoremap v $h

" Make Y behave like other capitals
nnoremap Y y$

" Do 'zz' after next candidates for search words
nnoremap n nzz
nnoremap N Nzz

" Search word under cursor
nnoremap S *zz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" View file information
nnoremap <C-g> 1<C-g>

" Write only when the buffer has been modified
nnoremap <silent><CR> :<C-u>silent update<CR>

" Goto file under cursor
noremap gf gF
noremap gF gf

" Jump a next blank line
nnoremap <silent>W :<C-u>keepjumps normal! }<CR>
nnoremap <silent>B :<C-u>keepjumps normal! {<CR>

" Save word and exchange it under cursor
nnoremap <silent> ciy ciw<C-r>0<ESC>:let@/=@1<CR>:noh<CR>
nnoremap <silent> cy   ce<C-r>0<ESC>:let@/=@1<CR>:noh<CR>

" Yank the entire file
nnoremap <Leader>y :<C-u>%y<CR>
nnoremap <Leader>Y :<C-u>%y<CR>

" Emacs-kile keybindings in insert mode {{{2
inoremap <C-a> <Home>
inoremap <C-e> <End>
inoremap <C-h> <BS>
inoremap <C-d> <Del>
inoremap <C-f> <Right>
inoremap <C-b> <Left>
inoremap <C-n> <Up>
inoremap <C-p> <Down>
inoremap <C-m> <CR>

" __END__ {{{1
" vim:fdm=marker expandtab fdc=3:
