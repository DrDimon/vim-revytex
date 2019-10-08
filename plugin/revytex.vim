" usage:
" lines starting with % are comments
" customization:
" disable key mappings:
" let g:revytex_no_mappings = 1
" use default author:
" let g:revytex_default_author = 'Preben'
if !exists("g:revytex_command")
  let g:revytex_command = "revytex"
endif

" Says()
"Changes from:
"   adf afd asdf 
" p : adfasdf asdf
" p [ adf ] : aaaa bbb
"To:
"\says{} adf afd asdf 
"\says{P} adfasdf asdf
"\says{P}[adf] aaaa bbb
" First char inside {} are made upper case
function! Says()
  let line = getline('.')

  " ignore comments:
  if( line =~ '^\s*%' )
    return
  endif

  " format:
  if( line =~ '^.\{-}\[.\{-}\]\s*:' )
    silent! s/^\s*\(.\{-}\)\s*\[\s*\(.\{-}\)\s*\]\s*:/\\says{\u\1}[\2]/
  elseif( line =~ '^.\{-}\s*:' )
    silent! s/^\s*\(.\{-}\)\s*:/\\says{\u\1}/
  else 
    silent! s/^\s*/\\says{} /
    " move cursor to }
    :normal wwl
  endif

  call repeat#set("\<Plug>Says", v:count)
endfunction

function! Scene() range
  let line       = join(getline(a:firstline, a:lastline))
  " Ignore empty lines and comments:
  if(!(line =~ '^\s*$\|^\s*%'))
    call cursor(a:firstline, 0)
    s/^\s*//
    norm 0i\scene{
    call cursor(a:lastline, 0)
    s/\s*$//
    norm $a}
  endif
  call repeat#set("\<Plug>Scene", v:count)
endfunction

function! Sings()
  let line = getline('.')
  if( line =~ ':' )
    s/^\(.*\):/\\sings{\1}/
  else
    ?.*:\|^s*$? s/^\(.*\):/\\sings{\1}/
  endif
  " Go to the end of the \sing
  let last_line = search('.*:\|^s*$', 'W')
  if( last_line )
    call cursor( last_line -1, 0 )
  else
    call cursor( '$', 0 )
  endif
  
  call repeat#set("\<Plug>Sings", v:count)
endfunction

function! Role()
  norm 0i\role{
  norm f:r}a[]
  call repeat#set("\<Plug>Role", v:count)
endfunction

function! FormatSketch() range
  " Rewrite lines
  silent! :exe a:firstline . ',' . a:lastline . ' v/.*:/ call Scene()'
  silent! :exe a:firstline . ',' . a:lastline . ' g/.*:/ call Says()'
  " Clean multiline scenes:
  silent! :exe a:firstline . ',' . a:lastline . ' s/}\n\\scene{/\r/g'
endfunction

" Add a role between \begin{role}...\end{role}:
function! s:AddRole(abbr, name)
  let role_linenr = search('^\\begin{roles}', 'n')
  if( role_linenr )
    call append(role_linenr, '\role{' . a:abbr . '}[] ' . a:name)
  else
    echoerr 'AddRole called without a role tag'
  endif
endfunction

" Add all roles who have \says to rolelist
function! s:UpdateRoles()
  normal G$
  let names = []
  let flags = "w"
  " Find all says tags, and extract who says it
  while search('\\says{.*}\|\\sings{.*}', flags) > 0
    let line = getline('.') " Read the line with a match
    let name = ''
    if line =~ '\\says'
      let name = matchstr(line,'\\says{.\{-}}')
      let name = name[6:-2] " extract the inside of {}
    else
      let name = matchstr(line,'\\sings{.\{-}}')
      let name = name[7:-2]
    endif
    let names = names + split(name, '[ ,+-]') " Split tags where multiple people says somethig
    let flags = "W"
  endwhile
  call uniq(sort(names))
  if len(names) > 0
    for name in names
      call s:AddRole(name, '')
    endfor
  " revytex wont compile if roles are empty
  else
    call s:AddRole('P', '')
  endif
endfunction

function! ToSketch()
  :0,$ call FormatSketch()
  call s:SketchPrefix(0)
  call append(line('$'), ['', '', '\end{sketch}', '\end{document}'])
endfunction

function! FormatSong() range
  let mode = 0
  call cursor( a:firstline, 0 )
  " if the current line is a \sings, we must look at the 
  " start of the \sings (the pervious line containing ':')
  " but if a blank line is inbetween this line is a \scene instead.
  let linenr = search('^\s*$\|:\|\\', 'Wb')
  " if the first line is part of a \sings, we go to the start of that \sings
  if !(getline(linenr) =~ ':')
    let linenr = a:firstline
  endif
  let linenr = linenr - (linenr > 0 ? 1 : 0)
  while linenr < a:lastline
    let linenr += 1
    call cursor( linenr, 0 )
    let line = getline('.')
    " if the line is empty, we reset mode, and write the closing '}' of
    " the previous new \scene{ if there is one.
    if( (line =~ '^\s*$') )
      if( mode == 2 )
        normal -A}
        normal +
      endif
      let mode = 0
    else
      " If there is already a tag:
      if( line =~ '^\\sings{' )
        if( mode == 2 ) " end previous \scene{ if there is one
          normal -A}
          normal +
        endif
        let mode = 1
      elseif( line =~ '^\\scene{' )
        " go to end of current \scene{ tag:
        :normal f{%
        let linenr = line('.')
      else
        " else we check if it is a \sings or \scene depending on ':'
        if( mode == 0 || line =~ ':')
          if( line =~ ':' )
            if( mode == 2 ) " end previous \scene{ if there is one
              normal -A}
              normal +
            endif
            let mode = 1
            call Sings() " we only need to call this once
          else
            " create opening \scene
            let mode = 2
            :normal 0i\scene{
          endif
        endif
      endif
    endif
  endwhile
  " if we finish in a '\scene{' we write the ending '}'
  if( mode == 2 )
    normal A}
  endif
  if( a:firstline == a:lastline )
    call repeat#set("\<Plug>FormatSong", v:count)
  endif
endfunction

function! ToSong()
  :% call FormatSong()
  call s:SketchPrefix(1)
  call append(line('$'), ['', '', '\end{song}', '\end{document}'])
endfunction

function! s:SketchPrefix(is_song)
  let title  = substitute(expand('%:r:t'), '^\(.*\)$', '\u\1', '')
  let title  = substitute( title, '[_-]', ' ', 'g')
  call inputsave()
  let title  = input('title(' . title . '): ', title)
  let time   = input('time: ', 'n')
  let status = input('status: ', 'Ikke færdig')
  let author = input('author: ', exists('g:revytex_default_author') ? g:revytex_default_author : '')
  let melody = a:is_song ? input('melody (yt-link): ') : ''
  call inputrestore()
  call append(0, [
      \ '\documentclass[a4paper,11pt]{article}',
      \ '',
      \ '\usepackage{revy}',
      \ '\usepackage[utf8]{inputenc}',
      \ '\usepackage[T1]{fontenc}',
      \ '\usepackage[danish]{babel}',
      \ '',
      \ '',
      \ '\revyname{DIKUrevy}',
      \ '\revyyear{' . strftime("%Y") . '}',
      \ '\version{0.1}',
      \ '\eta{$' . time . '$ minutter}',
      \ '\status{' . status . '}',
      \ '',
      \ '\title{' . title . '}',
      \ '\author{' . author . '}',
      \ a:is_song ? '\melody{Kunstner: ' . melody . '}' : '',
      \ '',
      \ '\begin{document}',
      \ '\maketitle',
      \ '',
      \ '\begin{roles}',
      \ '\end{roles}',
      \ '',
      \ '\begin{props}',
      \ '\prop{Rekvisit}[]',
      \ '\end{props}',
      \ '',
      \ '',
      \ a:is_song ? '\begin{song}' : '\begin{sketch}',
      \ '',
      \ ''
  \ ])
  call s:UpdateRoles()
endfunction

" Export:
noremap <silent> <Plug>Says         :<C-U>call Says()<CR>
noremap <silent> <Plug>Scene        :<C-U>call Scene()<CR>
noremap <silent> <Plug>Sings        :<C-U>call Sings()<CR>
noremap <silent> <Plug>Role         :<C-U>call Role()<CR>
noremap <silent> <Plug>FormatSketch :<C-U>call FormatSketch()<CR>
noremap <silent> <Plug>FormatSong   :<C-U>call FormatSong()<CR>
"command! RevytexSays                call Says()
"command! -range RevytexScene        <line1>,<line2>call Scene()
"command! RevytexRole                call Role()
"command! -range RevytexFormatSketch <line1>,<line2>call FormatSketch()
"command! -range RevytexFormatSong   <line1>,<line2>call FormatSong()
command! RevytexToSketch            call ToSketch()
command! RevytexToSong              call ToSong()

if !exists("g:revytex_no_mappings") || ! g:revytex_no_mappings
  vmap s <Nop>
  nmap sq <Plug>FormatSketch()<CR>
  vmap sq :call FormatSketch()<CR>
  nmap sa <Plug>FormatSong()<CR>
  vmap sa :call FormatSong()<CR>
endif
