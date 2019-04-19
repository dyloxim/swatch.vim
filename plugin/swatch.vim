" {{{ New_adjustment ❯
function! New_adjustment(...)
  if len(a:) < 5 | let group = Get_group() | else | let group = get(a:, 1) | endif
  let attributes = Get_attributes(l:group)
  let alteration_file = g:swatch_dir . 'alterations/'
        \. (exists('g:colors_name') ? g:colors_name : 'default')
        \. '.vim'

  if bufwinnr(alteration_file) == -1
    wincmd v | wincmd L | exe '50 wincmd |'
    exe 'edit ' . l:alteration_file
    if !filereadable(l:alteration_file)
      call Insert_template()
      call append(0, '" vim:tw=78:ts=2:sw=2:et:fdm=marker:')
      write alteration_file
      edit
    endif
  else
    exe bufwinnr(alteration_file) . 'wincmd w'
  endif

  silent if !search(l:group, 'n')
    call Insert_group(group, attributes)
    normal zMgg
    call search(group)
    normal zv3j
  endif
endfunction
" }}} New_adjustment ❮
" {{{ Insert_group ❯
function! Insert_group(group, attributes)
  let [fg, bg, styles] = [
        \a:attributes[0], 
        \a:attributes[1], 
        \Style_decode(a:attributes[2])
        \]
  let [fg, bg, styles] = map([fg, bg, styles], {k,v -> v == '' ? 'none' : v})
  call append(0, 
        \['"{{{ ' . a:group      ] +
        \['hi ' . a:group        ] +
        \['    \ gui=' . l:styles] +
        \['    \ guifg=' . l:fg  ] +
        \['    \ guibg=' . l:bg  ] +
        \['"}}} ' . a:group      ]
        \)
endfunction
" }}} Insert_group ❮
" {{{ Get_attributes ❯
" return looks like ['fg', 'bg', 'styles']
function! Get_attributes(group)
  let hlID = hlID(a:group)
  return [
        \synIDattr(hlID, 'fg#'),
        \synIDattr(hlID, 'bg#'),
        \[(synIDattr(hlID, 'bold') == 1 ? 1 : 0), 
        \(synIDattr(hlID, 'italic') == 1 ? 1 : 0),
        \(synIDattr(hlID, 'undercurl') == 1 ? 2 :
        \(synIDattr(hlID, 'underline') == 1 ? 1 : 0)
        \)]
        \]
endfunction
" }}} Get_attributes ❮
" {{{ Style_encode ❯
function! Style_encode(style_string)
endfunction
" }}} Style_encode ❮
" {{{ Style_decode ❯
function! Style_decode(tally)
  return
    \ (a:tally[0] == 1 ? 'bold,'      : '') .
    \ (a:tally[1] == 1 ? 'italic,'    : '') .
    \ (a:tally[2] == 1 ? 'underline,' : '') .
    \ (a:tally[2] == 2 ? 'undercurl,' : '')
endfunction
" }}} Style_decode ❮
" {{{ Insert_template ❯
function! Insert_template()
  for group in [
        \'FoldColumn', 'Cursor', 'VertSplit',
        \'Folded', 'Visual', 'Search',
        \'IncSearch', 'LineNR', 'CursorLineNR',
        \'CursorLine', 'SpellBad'',', 'SpellCap',
        \'SpellRare', 'SpellLocal', 'NonText',
        \'MatchParen']
    redir => group_information | silent exe "hi" group | redir END
    let [style, fg, bg] = ['none', 'none', 'none']
    for attr in attributes
      if attr =~ 'gui=' | let style = attr[4:] | endif
      if attr =~ 'guifg=' | let fg    = attr[6:] | endif
      if attr =~ 'guibg=' | let bg    = attr[6:] | endif
    endfor
    echo [style, fg, bg]
    call append(0,
          \['"{{{ ' . group     ] +
          \['hi ' . group       ] +
          \['    \ gui=' . style] +
          \['    \ guifg=' . fg ] +
          \['    \ guibg=' . bg ] +
          \['"}}} ' . group     ]
          \)
    call append(0, '"↓ Difficult to identify groups ↓')
endfunction
" }}} Insert_template ❮
" {{{ Adjust_Levels ❯
function! Adjust_Levels(channel, delta, ...)
  let a:audit = get(a:, 1, v:true)
  let s:in_visual = get(a:, 2, v:false)

  if a:audit == v:true
    call Audit(a:channel, a:delta)
  else
    if s:context == 'hidef'
      let group = Get_group('hidef')
      call Position_cursor('hidef')
    elseif s:context == 'hex'
      call Position_cursor('hex')
    elseif s:context == 'preview'
    endif
  endif
endfunction
" }}} Adjust_Levels ❮
" {{{ Position_cursor ❯
function! Position_cursor(context)
  let cword = expand('<cword>')
  let cWORD = expand('<cWORD>')
  if a:context == 'hidef'
    if cWORD =~ '\vgui(fg|bg)?\=#[a-fA-F0-9]{6}'
      normal Ebl
    else
      call search('\vgui(fg|bg)?\=') | normal Ebl
    endif
  elseif a:context == 'hex'
    if cword =~ '\v#[a-fA-F0-9]{6}' 
          \&& !(getline('.')[col('.')-1] =~ '\s')
      if getline('.')[col('.')-1] == '#'
        normal l
      else
        normal bl
      endif
    else
      echo 'asdfsf'
      call search('\v#[a-fA-F0-9]{6}')
        normal l
    endif
  endif
endfunction
" }}} Position_cursor ❮
" {{{ Get_last ❯
function! Get_last(value)
  if a:value == 'trigger_line'
    return s:last_hidef_line
  elseif a:value == 'cursor_line'
    return s:last_cursor_line
  endif
endfunction
" }}} Get_last ❮
" {{{ Set_last ❯
function! Set_last(value)
  if a:value == 'hidef_line'
    let s:last_hidef_line = line('.')
  elseif a:value == 'cursor_line'
    let s:last_cursor_line = line('.')
  endif
endfunction
" }}} Set_last ❮
" {{{ Get_current_line ❯
function! Get_current_line()
  return line('.')
endfunction
" }}} Get_current_line ❮
" {{{ Audit ❯
function! Audit(channel, delta)
  if s:in_visual == v:true
    let s:context = 'in_visual'
    call Audit_for_preview(a:channel, a:delta)
  elseif On('hidef')
    let s:context = 'hidef'
    call Audit_for_hidef(a:channel, a:delta)
  elseif On('hex')
    let s:context = 'hex'
    call Audit_for_hex(a:channel, a:delta)
  else
    echo 'on nothing'
  endif
endfunction
" }}} Audit ❮
" {{{ Audit_for_hidef ❯
function! Audit_for_hidef(channel, delta)
  if Get_last('trigger_line') == Get_current_line()
    undojoin | call Adjust_Levels(a:channel, a:delta, v:false, 'hidef')
  else
    call Set_last('trigger_line')
    call Adjust_Levels(a:channel, a:delta, v:false, 'hidef')
  endif
endfunction
" }}} Audit_for_hidef ❮
" {{{ Audit_for_hex ❯
function! Audit_for_hex(channel, delta)
  if Get_last('trigger_line') == Get_current_line()
    undojoin | call Adjust_Levels(a:channel, a:delta, v:false, 'hex')
  else
    call Set_last('trigger_line')
    call Adjust_Levels(a:channel, a:delta, v:false, 'hex')
  endif
endfunction
" }}} Audit_for_hex ❮
" {{{ Audit_for_preview ❯
function! Audit_for_preview(...)
  if Get_last('trigger_line') == Get_current_line()
    undojoin | call Adjust_Levels(a:channel, a:delta, v:false, 'preview')
  else
    echo 'No color selected'
  endif
endfunction
" }}} Audit_for_preview ❮
" {{{ On ❯
function! On(thing)
  let line = getline('.')
  if a:thing == 'hidef'
    if line =~ '\vgui(fg|bg)?\='
      return v:true
    else
      return v:false
    endif
  elseif a:thing == 'hex'
    if line =~ '\v#[a-fA-F0-9]{6}'
      return v:true
    else
      return v:false
    endif
  endif
endfunction
" }}} On ❮
" {{{ Set_Shortcuts ❯
function! Set_Shortcuts(channels)
  for i in range(0,2)
    exe 'nnoremap <m-' . a:channels[l:i][0] . '> '
          \. ':call Adjust_Levels(' . l:i . ',1)<cr>'
    exe 'nnoremap <m-' . a:channels[l:i][1] . '> '
          \. ':call Adjust_Levels(' . l:i . ',-1)<cr>'
    exe 'vnoremap <m-' . a:channels[l:i][0] . '> '
          \. ":<c-u>'>call Adjust_Levels(" . l:i . ',1,'
          \. 'v:true, v:true)<cr>' 
    exe 'vnoremap <m-' . a:channels[l:i][1] . '> '
          \. ":<c-u>'>call Adjust_Levels(" . l:i . ',-1,'
          \. 'v:true, v:true)<cr>'
  endfor
endfunction
" }}} Set_Shortcuts ❮
" {{{ Get_group ❯
function! Get_group(context)
  if a:context == 'cursor'
    let stack = synstack(line("."),col("."))
    let syntaxes = []
    for i in range(0,len(l:stack)-1)
      let l:syntaxes = add(l:syntaxes,
            \[
            \l:stack[l:i],
            \synIDattr(l:stack[l:i], "name"),
            \synIDattr(synIDtrans(l:stack[l:i]), "name")
            \])
    endfor
    if len(l:syntaxes) == 0
      let l:syntaxes = [[0,"Normal","Normal"]]
    endif
    let synlist = map(deepcopy(l:syntaxes), {
          \k,v -> printf("%s. %s -> %s -> %s", k+1, v[0], v[1], 
          \v[1] == v[2] ? "-" : v[2])
          \})
    let choice = inputlist(
          \["Choose highlight group you wish to alter"]
          \+ l:synlist
          \)
    return l:syntaxes[l:choice-1][2]
  elseif a:context == 'hidef'
    call Move_cursor([0,1])
    let line_num = search('\vhi(light)? \w+', 'bn')
    call Move_cursor([0,-1])
    return split(getline(line_num))[1]
  endif
endfunction
" }}} Get_group ❮
" {{{ Move_cursor ❯
function! Move_cursor(instruction)
  if len(a:instruction) == 2
    let [x,y] = [a:instruction[0], a:instruction[1]]
    call cursor(line('.') + x, col('.') + y)
  elseif a:instruction == '0'
    call cursor(line('.'), 1)
  endif
endfunction
" }}} Move_cursor ❮

" {{{ Variables ❯
let s:last_hidef_line = 0
let s:last_cursor_line = 0
let s:in_visual = v:false
let g:swatch_dir = 'Users/Joel/.config/nvim/rc/swatch/'
" }}} Variables ❮

call Set_Shortcuts([['w','s'],['e','d'],['r','f']])
nnoremap <leader>ss :call New_adjustment()<cr>

" hi Normal guibg=#aaaaaa guifg=#aaaaaa
" #aaaaaa '#aaaaaa' #aaaaaa

" vim:tw=78:ts=2:sw=2:et:fdm=marker:
