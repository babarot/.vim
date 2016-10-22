if !exists('g:env')
  finish
endif

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

" Kill buffer
if !g:plug.is_installed('vim-buftabs')
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


function! s:buf_delete(bang) "{{{1
  let file = fnamemodify(expand('%'), ':p')
  let g:buf_delete_safety_mode = 1
  let g:buf_delete_custom_command = "system(printf('%s %s', 'gomi', shellescape(file)))"

  if filereadable(file)
    if empty(a:bang)
      redraw | echo 'Delete "' . file . '"? [y/N]: '
    endif
    if !empty(a:bang) || nr2char(getchar()) ==? 'y'
      silent! update
      if g:buf_delete_safety_mode == 1
        silent! execute has('clipboard') ? '%yank "*' : '%yank'
      endif
      if eval(g:buf_delete_custom_command == "" ? delete(file) : g:buf_delete_custom_command) == 0
        let bufname = bufname(fnamemodify(file, ':p'))
        if bufexists(bufname) && buflisted(bufname)
          execute "bwipeout" bufname
        endif
        echo "Deleted '" . file . "', successfully!"
        return s:true
      endif
      "echo "Could not delete '" . file . "'"
      return Error("Could not delete '" . file . "'")
    else
      echo "Do nothing."
    endif
  else
    return Error("The '" . file . "' does not exist")
  endif
endfunction

" Delete the current buffer and the file.
command! -bang -nargs=0 -complete=buffer Delete call s:buf_delete(<bang>0)
nnoremap <silent> <C-x>d     :<C-u>Delete<CR>
nnoremap <silent> <C-x><C-d> :<C-u>Delete!<CR>

function! s:open(file) "{{{1
  if !g:env.bin.open
    return Error('open: not supported yet.')
  endif
  let file = empty(a:file) ? expand('%') : fnamemodify(a:file, ':p')
  call system(printf('%s %s &', 'open', shellescape(file)))
  return v:shell_error ? g:false : g:true
endfunction

command! -nargs=? -complete=file Open call <SID>open(<q-args>)
command! -nargs=0                Op   call <SID>open('.')

function! s:load_source(path) "{{{1
  let path = expand(a:path)
  if filereadable(path)
    execute 'source ' . path
  endif
endfunction
" Source file
command! -nargs=? Source call <SID>load_source(empty(<q-args>) ? expand('%:p') : <q-args>)

function! s:copy_current_path(...) "{{{1
  let path = a:0 ? expand('%:p:h') : expand('%:p')
  if IsWindows()
    let @* = substitute(path, '\\/', '\\', 'g')
  else
    let @* = path
  endif
  echo path
endfunction

" Get current file path
command! CopyCurrentPath call s:copy_current_path()
" Get current directory path
command! CopyCurrentDir call s:copy_current_path(1)
command! CopyPath CopyCurrentPath

function! s:make_junkfile() "{{{1
  let junk_dir = $HOME . '/.vim/junk'. strftime('/%Y/%m/%d')
  if !isdirectory(junk_dir)
    call s:mkdir(junk_dir)
  endif

  let ext = input('Junk Ext: ')
  let filename = junk_dir . tolower(strftime('/%A')) . strftime('_%H%M%S')
  if !empty(ext)
    let filename = filename . '.' . ext
  endif
  execute 'edit ' . filename
endfunction

" Make the notitle file called 'Junk'.
command! -nargs=0 JunkFile call s:make_junkfile()

function! s:rename(new, type) "{{{1
  if a:type ==# 'file'
    if empty(a:new)
      let new = input('New filename: ', expand('%:p:h') . '/', 'file')
    else
      let new = a:new
    endif
  elseif a:type ==# 'ext'
    if empty(a:new)
      let ext = input('New extention: ', '', 'filetype')
      let new = expand('%:p:t:r')
      if !empty(ext)
        let new .= '.' . ext
      endif
    else
      let new = expand('%:p:t:r') . '.' . a:new
    endif
  endif

  if filereadable(new)
    redraw
    echo printf("overwrite `%s'? ", new)
    if nr2char(getchar()) ==? 'y'
      silent call delete(new)
    else
      return s:false
    endif
  endif

  if new != '' && new !=# 'file'
    let oldpwd = getcwd()
    lcd %:p:h
    execute 'file' new
    execute 'setlocal filetype=' . fnamemodify(new, ':e')
    write
    call delete(expand('#'))
    execute 'lcd' oldpwd
  endif
endfunction

" Rename the current editing file
command! -nargs=? -complete=file Rename call s:rename(<q-args>, 'file')

" Change the current editing file extention
if v:version >= 730
  command! -nargs=? -complete=filetype ReExt  call s:rename(<q-args>, 'ext')
else
  command! -nargs=?                    ReExt  call s:rename(<q-args>, 'ext')
endif

function! s:smart_execute(expr) "{{{1
  let wininfo = winsaveview()
  execute a:expr
  call winrestview(wininfo)
endfunction

" Remove EOL ^M
command! RemoveCr call s:smart_execute('silent! %substitute/\r$//g | nohlsearch')
" Remove EOL space
command! RemoveEolSpace call s:smart_execute('silent! %substitute/ \+$//g | nohlsearch')

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

" __END__ {{{1
" vim:fdm=marker expandtab fdc=3:
