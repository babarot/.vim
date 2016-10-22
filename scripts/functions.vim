if !exists('g:env')
  finish
endif

function! s:has_plugin(name) "{{{1
  " Check {name} plugin whether there is in the runtime path
  let nosuffix = a:name =~? '\.vim$' ? a:name[:-5] : a:name
  let suffix   = a:name =~? '\.vim$' ? a:name      : a:name . '.vim'
  return &rtp =~# '\c\<' . nosuffix . '\>'
        \   || globpath(&rtp, suffix, 1) != ''
        \   || globpath(&rtp, nosuffix, 1) != ''
        \   || globpath(&rtp, 'autoload/' . suffix, 1) != ''
        \   || globpath(&rtp, 'autoload/' . tolower(suffix), 1) != ''
endfunction

function! s:mkdir(dir) "{{{1
  if !exists("*mkdir")
    return g:false
  endif

  let dir = expand(a:dir)
  if isdirectory(dir)
    return g:true
  endif

  return mkdir(dir, "p")
endfunction

function! Mkdir(dir) abort
  return s:mkdir(a:dir)
endfunction

function! GetBufname(bufnr, ...) "{{{1
  let bufname = bufname(a:bufnr)
  if bufname =~# '^[[:alnum:].+-]\+:\\\\'
    let bufname = substitute(bufname, '\\', '/', 'g')
  endif
  let buftype = getbufvar(a:bufnr, '&buftype')
  if bufname ==# ''
    if buftype ==# ''
      return '[No Name]'
    elseif buftype ==# 'quickfix'
      return '[Quickfix List]'
    elseif buftype ==# 'nofile' || buftype ==# 'acwrite'
      return '[Scratch]'
    endif
  endif
  if buftype ==# 'nofile' || buftype ==# 'acwrite'
    return bufname
  endif
  if a:0 && a:1 ==# 't'
    return fnamemodify(bufname, ':t')
  elseif a:0 && a:1 ==# 'f'
    return (fnamemodify(bufname, ':~:p'))
  elseif a:0 && a:1 ==# 's'
    return pathshorten(fnamemodify(bufname, ':~:h')).'/'.fnamemodify(bufname, ':t')
  endif
  return bufname
endfunction

command! -nargs=? -complete=file -bang Ls2 call s:ls('<args>', '<bang>')
function! s:ls(path, bang)
  let path = empty(a:path) ? getcwd() : expand(a:path)
  if filereadable(path)
    if executable("ls")
      echo system("ls -l " . path)
      return v:shell_error ? g:false : g:true
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

  let max = 0
  for item in lists
    let max += len(item)
    if max > &columns * 1.5
      echon "...more"
      break
    endif
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

  return g:true
endfunction

" __END__ {{{1
" vim:fdm=marker expandtab fdc=3:
