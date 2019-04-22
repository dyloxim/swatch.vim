" Swatch: a great plugin by Joel Strouts

" {{{ API ❯
" {{{ Swatch_new_adjustment ❯
function! Swatch_new_adjustment(...)
  if len(a:) < 5 | let group = s:Get_group('cursor') | else | let group = get(a:, 1) | endif
  if group != ''
    let attributes = s:Get_attributes_string(group)
    let file_path = s:Get_alterations_file()
    if s:Swatch_Buffer_Open()
      exe bufwinnr(file_path) . 'wincmd w'
    else
      wincmd v | wincmd L | exe '50 wincmd |'
      if !filereadable(file_path)
        call s:Init_alterations_file(file_path)
      endif
      exe 'edit ' . file_path
    endif
    silent if !search(l:group, 'n')
      call s:Insert_group(group, attributes)
    endif
    normal! zMgg
    call search(group)
    normal! zv3j
  endif
endfunction
" }}} Swatch_new_adjustment ❮
" {{{ Swatch_adjust_levels ❯
function! Swatch_adjust_levels(channel, delta, ...)
  let a:audit = get(a:, 1, v:true)
  let s:in_visual = get(a:, 2, v:false)

  if a:audit == v:true | call s:Audit(a:channel, a:delta)
  else " audit already performed
    if s:context == 'hidef'
      call s:Set_last('trigger_pos')
      call s:Adjust_levels_HIDEF(a:channel, a:delta)
    elseif s:context == 'hex'
      call s:Set_last('trigger_pos')
      call s:Adjust_levels_HEX(a:channel, a:delta)
    elseif s:context == 'in_visual'
      call s:Adjust_levels_IN_VISUAL(a:channel, a:delta)
    endif
  endif
endfunction
" }}} Swatch_adjust_levels ❮
" {{{ Swatch_preview_this ❯
function! Swatch_preview_this()
  if s:On('hex')
    call s:Position_cursor_ON_HEX()
  elseif s:Has(getline('.'), 'hex')
    call s:Position_cursor_HAS_HIDEF()
  endif
  let hex = s:Get_hex('here')
  call s:Preview_hex(hex, 'word')
endfunction
" }}} Swatch_preview_this ❮
" {{{ Swatch_set_shortcuts ❯
function! Swatch_set_shortcuts(channels)
  for i in range(0,2)
    exe 'nnoremap <m-' . a:channels[l:i][0] . '> '
          \. ':call Swatch_adjust_levels(' . l:i . ',1)<cr>'
    exe 'nnoremap <m-' . a:channels[l:i][1] . '> '
          \. ':call Swatch_adjust_levels(' . l:i . ',-1)<cr>'
    exe 'vnoremap <m-' . a:channels[l:i][0] . '> '
          \. ":<c-u>'>call Swatch_adjust_levels(" . l:i . ',1,'
          \. 'v:true, v:true)<cr>' 
    exe 'vnoremap <m-' . a:channels[l:i][1] . '> '
          \. ":<c-u>'>call Swatch_adjust_levels(" . l:i . ',-1,'
          \. 'v:true, v:true)<cr>'
  endfor
endfunction
" }}} Swatch_set_shortcuts ❮
" {{{ Variables ❯
let g:swatch_step = 5
let g:swatch_dir = '/Users/Joel/.config/nvim/rc/swatch/user_data/'
let g:swatch_preview_region = 'word'
let g:swatch_preview_style = 'bg'
" }}} Variables ❮
" }}} API ❮
" {{{ Backend ❯
" {{{ Audits ❯
" {{{ Audit ❯
function! s:Audit(channel, delta)
  if s:in_visual == v:true
    let s:context = 'in_visual' | call s:Audit_IN_VISUAL(a:channel, a:delta)
  elseif s:On('hidef')
    call s:Position_cursor_ON_HIDEF()
    let s:context = 'hidef' | call s:Audit_HIDEF(a:channel, a:delta)
  elseif s:On('hex')
    call s:Position_cursor_ON_HEX()
    let s:context = 'hex' | call s:Audit_HEX(a:channel, a:delta)
  elseif s:Has(getline('.'), 'hidef')
    call s:Position_cursor_HAS_HIDEF()
    let s:context = 'hidef' | call s:Audit_HIDEF(a:channel, a:delta)
  elseif s:Has(getline('.'), 'hex')
    call s:Position_cursor_HAS_HEX()
    let s:context = 'hex' | call s:Audit_HEX(a:channel, a:delta)
  else
    echo 'on nothing'
  endif
endfunction
" }}} Audit ❮
" {{{ Audit_HIDEF ❯
function! s:Audit_HIDEF(channel, delta)
  if s:Get_last('trigger_pos')[0] == s:Get_current('line')
    undojoin | call s:Adjust_levels_HIDEF(a:channel, a:delta)
  else
    call s:Set_last('trigger_pos')
    call s:Adjust_levels_HIDEF(a:channel, a:delta)
  endif
endfunction
" }}} Audit_HIDEF ❮
" {{{ Audit_HEX ❯
function! s:Audit_HEX(channel, delta)
  call s:Set_last('trigger_pos')
  call s:Adjust_levels_HEX(a:channel, a:delta)
endfunction
" }}} Audit_HEX ❮
" {{{ Audit_IN_VISUAL ❯
function! s:Audit_IN_VISUAL(channel, delta)
  if s:Get_last('cursor_pos')[0] == s:Get_current('pos')[0]
    undojoin | call s:Adjust_levels_IN_VISUAL(a:channel, a:delta)
  else
    echo 'No color selected'
  endif
endfunction
" }}} Audit_IN_VISUAL ❮
" {{{ Is_color ❯
function! s:Is_color(name)
  if nvim_get_color_by_name(a:name) != -1
    return v:true
  else
    return v:false
  endif
endfunction
" }}} Is_color ❮
" {{{ Is_style ❯
function! s:Is_style(name)
  if a:name =~ '\v(none|fg|bg|bold|italic|underline|undercurl|reverse)'
    return v:true
  else
    return v:false
  endif
endfunction
" }}} Is_style ❮
" }}} Audits ❮
" {{{ Adjust_levels ❯
" {{{ Adjust_levels_HIDEF ❯
function! s:Adjust_levels_HIDEF(channel, delta)
  let group = s:Get_group('hidef')
  let key = s:Get_hidef('key') | let value = s:Get_hidef('value')
  if key == 'gui'
    let new_style_string = s:Transform_style(value, a:channel, a:delta)
    call s:Apply_style(group, key, new_style_string)
    call s:Replace_hidef(key, new_style_string)
  else " key is fg or bg
    if value[0] =~ '\u' 
      let value = s:Get_hex_from_name(value)
    endif
    let new_hex = s:Transform_hex(value, a:channel, a:delta)
    call s:Apply_style(group, key, new_hex)
    call s:Replace_hidef(key, new_hex)
  endif
endfunction
" }}} Adjust_levels_HIDEF ❮
" {{{ Adjust_levels_HEX ❯
function! s:Adjust_levels_HEX(channel, delta)
  let old = s:Get_hex('here') | let new = s:Transform_hex(old, a:channel, a:delta)
  let name_color = nvim_get_color_by_name(old)
  if name_color != -1
    let new = s:Get_hex_from_name(old)
    call s:Replace_hex(old, '#' . new)
  else
    call s:Replace_hex(old, new)
  endif
  call s:Preview_hex(new)
endfunction
" }}} Adjust_levels_HEX ❮
" {{{ Adjust_levels_IN_VISUAL ❯
function! s:Adjust_levels_IN_VISUAL(channel, delta)
  let hex = s:Get_hex('elsewhere') | let new_hex = s:Transform_hex(hex, a:channel, a:delta)
  call s:Replace_hex(hex, new_hex)
  call s:Preview_hex(new_hex)
endfunction
" }}} Adjust_levels_IN_VISUAL ❮
" }}} Adjust_levels ❮
" {{{ Get & Set ❯
" {{{ Get_hex_from_name ❯
function! s:Get_hex_from_name(name)
  let binary_color = printf('%024b', nvim_get_color_by_name(a:name))
  let hex = join(map([
        \binary_color[0:7],
        \binary_color[8:15], 
        \binary_color[16:23]
        \],
        \{k,v -> printf('%02x', '0b' . v)}), '')
  return hex
endfunction
" }}} Get_hex_from_name ❮
" {{{ Get_attributes_string ❯
function! s:Get_attributes_string(group)
  redir => group_information | silent exe "hi" a:group | redir END
  let attributes = filter(split(l:group_information), {
        \k,v -> match(v, 'gui') != '-1'
        \})
  let [style, fg, bg] = ['none', 'none', 'none']
  for attr in attributes
    if attr =~ '\vgui\=.+'   | let style = attr[4:] | endif
    if attr =~ '\vguifg\=.+' | let fg    = attr[6:] | endif
    if attr =~ '\vguibg\=.+' | let bg    = attr[6:] | endif
  endfor
  return [style] + map([fg, bg], {k,v -> substitute(v, '#\+', '', 'g')})
endfunction
" }}} Get_attributes_string ❮
" {{{ Get_attributes_tally ❯
" return looks like ['fg', 'bg', 'styles']
function! s:Get_style_tally(group)
  let hlID = hls:ID(a:group)
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
" }}} Get_attributes_tally ❮
" {{{ Get_alterations_file ❯
function! s:Get_alterations_file()
  return g:swatch_dir . 'alterations/'
        \. s:Colors_name()
        \. '.vim'
endfunction
" }}} Get_alterations_file ❮
" {{{ Get_alterations ❯
function! s:Get_alterations()
  if filereadable(s:Get_alterations_file())
    let list = filter(readfile(s:Get_alterations_file()),
          \{k,v -> v[0] == '"' || v =~ '^\s*$' ? v:false : v:true})
    let alterations = map(copy(list), 
          \{k,v -> k % 4 == 0 ? 
          \[split(list[k])[-1], 
          \split(list[k+1], '=')[-1],
          \split(list[k+2], '=')[-1],
          \split(list[k+3], '=')[-1]] :
          \['remove']})
    let alterations = filter(alterations,
          \{k,v -> v == ['remove'] ? v:false : v:true})
    return map(alterations, {k,v -> [
          \v[0],
          \v[1],
          \substitute(v[2], '#', '', 'g'),
          \substitute(v[3], '#', '', 'g')
          \]})
  else
    return []
  endif
endfunction
" }}} Get_alterations ❮
" {{{ Get_template ❯
function! s:Get_template()
  let template = [''] + ['"↓ Difficult to identify groups ↓']
  for group in [
        \'Folded', 'Visual', 'Search',
        \'IncSearch', 'LineNR', 'CursorLineNR',
        \'CursorLine', 'SpellBad', 'SpellCap',
        \'SpellRare', 'SpellLocal', 'NonText',
        \'FoldColumn', 'Cursor', 'VertSplit',
        \'MatchParen']
    let [style, fg, bg] = s:Get_attributes_string(group)
    let [fg, bg] = map([fg, bg], 
        \{k,v -> v[0] =~ '\u' ||  v =~ '\v(none|fg|bg)' ? v : '#' . v})
    let template = template +
        \['"{{{ '        . group] +
        \['hi '          . group] +
        \['    \ gui='   . style] +
        \['    \ guifg=' . fg   ] +
        \['    \ guibg=' . bg   ] +
        \['"}}} '        . group]
  endfor
  let template = template + [''] + ['" for a complete list of groups see the file :so $VIMRUNTIME/syntax/hitest.vim'] + [''] +
        \ ['" vim:tw=78:ts=2:sw=2:et:fdm=marker:']
  return template
endfunction
" }}} Get_template ❮
" {{{ Get_hex ❯
function! s:Get_hex(context)
  if a:context == 'here'
    let hex = substitute(split(expand('<cword>'), '=')[-1], '#', '', 'g')
  elseif a:context == 'elsewhere'
    call cursor(s:last_trigger_pos)
    let hex = substitute(split(expand('<cword>'), '=')[-1], '#', '', 'g')
    call cursor(s:last_cursor_pos)
  endif
  return hex
endfunction
" }}} Get_hex ❮
" {{{ Get_group ❯
function! s:Get_group(context)
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
      let l:syntaxes = [[0,"normal","normal"]]
    endif
    let synlist = map(deepcopy(l:syntaxes), {
          \k,v -> printf("%s. %s -> %s -> %s", k+1, v[0], v[1], 
          \v[1] == v[2] ? "-" : v[2])
          \})
    let choice = inputlist(
          \["Choose highlight group you wish to alter"]
          \+ l:synlist
          \)
    return choice == 0 ? '' : l:syntaxes[choice-1][2]
  elseif a:context == 'hidef'
    call s:Move_cursor([0,1])
    let line_num = search('\vhi(light)? \w+', 'bn')
    call s:Move_cursor([0,-1])
    let tokens = split(getline(line_num))
    return filter(copy(tokens),
          \{k,v -> k == 0 ? v:false : (tokens[k-1] =~ '\vhi(light)?' ? v:true : v:false)})[0]
  endif
endfunction
" }}} Get_group ❮
" {{{ Get_hidef ❯
function! s:Get_hidef(attr)
  let cWORD = expand('<cWORD>')
  if a:attr == 'key'
    return split(cWORD, '=')[0]
  elseif a:attr == 'value'
    if cWORD =~ '#'
      return split(cWORD, '=')[1][1:]
    else
      return split(cWORD, '=')[1]
    endif
  endif
endfunction
" }}} Get_hidef ❮
" {{{ Colors_name ❯
function! s:Colors_name(...)
  return (exists('g:colors_name') ? g:colors_name : 'default')
endfunction
" }}} Colors_name ❮
" {{{ Cursor_char ❯
function! s:Cursor_char()
  return getline('.')[col('.')-1]
endfunction
" }}} Cursor_char ❮
" {{{ Get_last ❯
function! s:Get_last(value)
  if a:value == 'trigger_pos'
    return s:last_trigger_pos
  elseif a:value == 'cursor_pos'
    return s:last_cursor_pos
  endif
endfunction
" }}} Get_last ❮
" {{{ Set_last ❯
function! s:Set_last(value)
  if a:value == 'trigger_pos'
    let s:last_trigger_pos = [line('.'),col('.')]
  elseif a:value == 'cursor_pos'
    let s:last_cursor_pos = [line('.'),col('.')]
  endif
endfunction
" }}} Set_last ❮
" {{{ Get_current ❯
function! s:Get_current(thing)
  if a:thing == 'line'
    return line('.')
  elseif a:thing == 'pos'
    return [line('.'),col('.')]
  endif
endfunction
" }}} Get_current ❮
" }}} Get & Set ❮
" {{{ Windows & Files ❯
" {{{ Insert_group ❯
function! s:Insert_group(group, attributes)
  let [style, fg, bg] = a:attributes
  let [fg, bg] = map([fg, bg],
        \{k,v -> v[0] =~ '\u' ||  v =~ '\v(none|fg|bg)' ? v : '#' . v})
  call append(0, 
        \['" {{{ '        . a:group] +
        \['hi '          . a:group ] +
        \['    \ gui='   . l:style ] +
        \['    \ guifg=' . l:fg    ] +
        \['    \ guibg=' . l:bg    ] +
        \['" }}} '        . a:group]
        \)
endfunction
" }}} Insert_group ❮
" {{{ Init_alterations_file ❯
function! s:Init_alterations_file(path)
  let template = s:Get_template()
  exe '!mkdir -p ' . g:swatch_dir . 'alterations/'
  exe '!touch ' . a:path
  silent call writefile(template, a:path)
endfunction
" }}} Init_alterations_file ❮
" {{{ Swatch_Buffer_Open ❯
function! s:Swatch_Buffer_Open()
  let alteration_file = g:swatch_dir . 'alterations/'
        \. (exists('g:colors_name') ? g:colors_name : 'default')
        \. '.vim'
  if bufwinnr(alteration_file) == -1
    return v:false
  else
    return v:true
  endif
endfunction
" }}} Swatch_Buffer_Open ❮
" }}} Windows & Files ❮
" {{{ Replace / Load / styles ❯
" {{{ Replace_hex ❯
function! s:Replace_hex(old, new)
  exe s:last_trigger_pos[0] . 's/' . a:old . '/' . a:new
  call cursor(s:last_trigger_pos)
endfunction
" }}} Replace_hex ❮
" {{{ Replace_hidef ❯
function! s:Replace_hidef(key, value)
  exe 's/' . expand('<cWORD>') . '/' . a:key . '=' 
        \. (len(a:key) > 3 ? '#' : '') . a:value
  call cursor(s:last_trigger_pos)
endfunction
" }}} Replace_hidef ❮
" {{{ Apply_style ❯
function! s:Apply_style(group, key, value)
  let value =  s:Is_color(a:value) || 
        \s:Is_style(a:value) ?
        \ a:value :
        \ '#' . a:value
  let value = substitute(value, '\v^(.*)$', '\u\1', '')
  exe 'hi ' . a:group . ' ' . a:key . '=' . value
endfunction
" }}} Apply_style ❮
" {{{ Preview_hex ❯
function! s:Preview_hex(hex, ...)
  let s:OG_visual_hidef = s:Get_attributes_string('Visual')
  let a:preview_region = get(a:, 1, g:swatch_preview_region)
  let hex = s:Is_color(a:hex) || s:Is_style(a:hex) ? a:hex : '#' . a:hex
  echo hex

  if g:swatch_preview_style == 'fg'
    exe 'hi Visual guifg=' . hex
  elseif g:swatch_preview_style == 'bg'
    exe 'hi Visual guibg=' . hex
  elseif g:swatch_preview_style == 'both'
    exe 'hi Visual guifg=' . hex
    exe 'hi Visual guibg=' . hex
  endif

  if a:preview_region == 'screen'
    normal!! HVL
  elseif a:preview_region == 'para'
    normal!! vap
  elseif a:preview_region ==# 'WORD'
    normal!! viW
  elseif a:preview_region == 'word'
    normal! viw
  endif

  augroup Swatch
    au!
    au CursorMoved * call s:Reset_visual()
  augroup END

  call s:Set_last('cursor_pos')
endfunction
" }}} Preview_hex ❮
" {{{ Reset_visual ❯
function! s:Reset_visual()
  if s:Get_last('cursor_pos') != s:Get_current('pos')
    call s:Swatch_load(s:Colors_name(), 'Visual')
    augroup Swatch
      au!
    augroup END
  endif
endfunction
" }}} Reset_visual ❮
" {{{ Swatch_load ❯
function! s:Swatch_load(...)
  let colorscheme = get(a:, 1, s:Colors_name()) | let group = get(a:, 2, 'none')

  if group == 'none'
    exe 'colo ' . colorscheme
    if filereadable(s:Get_alterations_file())
      exe 'source ' . g:swatch_dir . 'alterations/' . colorscheme . '.vim'
    endif
  else | let group = get(a:, 2)
    let index = index(map(s:Get_alterations(), {k,v -> v[0]}), group)
    if index == -1
      let hidef = ['Visual'] + s:OG_visual_hidef
    else
      let hidef = s:Get_alterations()[index]
    endif
    call s:Apply_style(hidef[0], 'gui', hidef[1])
    call s:Apply_style(hidef[0], 'guifg', hidef[2])
    call s:Apply_style(hidef[0], 'guibg', hidef[3])
  endif
endfunction
" }}} Swatch_load ❮
" }}} Replace / Load styles ❮
" {{{ Cursor ❯
" {{{ Has ❯
function! s:Has(line, feature)
  if a:feature == 'hidef'
    if a:line =~ '\vgui(fg|bg)?\=' | return v:true | else | return v:false | endif
  elseif a:feature == 'hex'
    if a:line =~ '\v#[a-fA-F0-9]{6}' | return v:true | else | return v:false | endif
  endif
endfunction
" }}} Has ❮
" {{{ On ❯
function! s:On(feature)
  let cWORD = expand('<cWORD>')
  let cword = expand('<cword>')
  if a:feature == 'hidef'
    if cWORD =~ '\vgui(fg|bg)?\=' | return v:true | else | return v:false | endif
  elseif a:feature == 'hex'
    if cWORD =~ '\v#[a-fA-F0-9]{6}' ||
          \ nvim_get_color_by_name(cword) != -1
      return v:true
    else
      return v:false
    endif
  endif
endfunction
" }}} On ❮
" {{{ Position_cursor_ON_HIDEF ❯
function! s:Position_cursor_ON_HIDEF()
  let cword = expand('<cword>')
  if cword =~ 'gui'
    normal! Ebl
  else
    if s:Cursor_char() != cword[-1] && col('.') != col('$') - 1
      call search('\v(>)\@=', '')
    endif
    normal! bl
  endif
endfunction
" }}} Position_cursor_ON_HIDEF ❮
" {{{ Position_cursor_ON_HEX ❯
function! s:Position_cursor_ON_HEX()
  let cword = expand('<cword>')
  if cword =~ '#' 
    if s:Cursor_char() != '#'
    else
      normal! l
    endif
  else
    if s:Cursor_char() != cword[-1] && col('.') != col('$') - 1
      call search('\v(>)\@=', '')
    endif
    normal! bl
  endif
endfunction
" }}} Position_cursor_ON_HEX ❮
" {{{ Position_cursor_HAS_HIDEF ❯
function! s:Position_cursor_HAS_HIDEF()
  call search('=')
  call s:Position_cursor_ON_HIDEF()
endfunction
" }}} Position_cursor_HAS_HIDEF ❮
" {{{ Position_cursor_HAS_HEX ❯
function! s:Position_cursor_HAS_HEX()
  call search('#') | normal! l
endfunction
" }}} Position_cursor_HAS_HEX ❮
" {{{ Move_cursor ❯
function! s:Move_cursor(instruction)
  if len(a:instruction) == 2
    let [x,y] = [a:instruction[0], a:instruction[1]]
    call cursor(line('.') + x, col('.') + y)
  elseif a:instruction == '0'
    call cursor(line('.'), 1)
  endif
endfunction
" }}} Move_cursor ❮
" }}} Cursor ❮
" {{{ Computations ❯
" {{{ Vector_add ❯
function! s:Vector_add(vec1,vec2)
  if len(a:vec1) >= len(a:vec2)
    let return_vector = a:vec1
    for i in range(0,len(a:vec2)-1)
      let return_vector[i] = a:vec1[i] + a:vec2[i]
    endfor
    return l:return_vector
  else
    return s:Vector_add(a:vec2,a:vec1)
  endif
endfunction
" }}} Vector_add ❮
" {{{ Scale_vector ❯
function! s:Scale_vector(constant,vector)
  return map(copy(a:vector), {k,v -> a:constant * v})
endfunction
" }}} Scale_vector ❮
" {{{ Style_encode ❯
function! s:Style_encode(style_string)
  let styles = split(a:style_string, ',')
  let tally = [0,0,0]
  for style in styles
    if style =~ 'bold'      | let tally[0] = 1 | endif
    if style =~ 'italic'    | let tally[1] = 1 | endif
    if style =~ 'underline' | let tally[2] = 1 | endif
    if style =~ 'undercurl' | let tally[2] = 2 | endif
  endfor
  return tally
endfunction
" }}} Style_encode ❮
" {{{ Style_decode ❯
function! s:Style_decode(tally)
  if a:tally == [0,0,0]
    return 'none'
  else
    return
          \ (a:tally[0] == 1 ? 'bold,'      : '') .
          \ (a:tally[1] == 1 ? 'italic,'    : '') .
          \ (a:tally[2] == 1 ? 'underline,' : '') .
          \ (a:tally[2] == 2 ? 'undercurl,' : '')
  endif
endfunction
" }}} Style_decode ❮
" {{{ Transform_style ❯
function! s:Transform_style(style_string, channel, delta)
  let tally = s:Style_encode(a:style_string)
  let change = [[1,0,0],[0,1,0],[0,0,1]][a:channel]
  let tally = s:Vector_add(
        \copy(l:tally), 
        \s:Scale_vector(a:delta/abs(a:delta), l:change)
        \)
  let tally = s:Vector_add(tally, [2,2,3])
  let tally[0] = tally[0] % 2 | let tally[1] = tally[1] % 2
  let tally[2] = tally[2] % 3
  return s:Style_decode(tally)
endfunction
" }}} Transform_style ❮
" {{{ Transform_hex ❯
function! s:Transform_hex(hex, channel, delta)
  let rgb = s:Hex_to_RGB(a:hex)
  let new_rgb = s:Transform_rgb(rgb, a:channel, a:delta)
  let new_hex = s:RGB_to_hex(new_rgb)
  return new_hex
endfunction
" }}} Transform_hex ❮
" {{{ Transform_rgb ❯
function! s:Transform_rgb(rgb, channel, delta)
  let change = map([0,1,2], {k, v -> v == a:channel ? 1 : 0})
  let new = s:Vector_add(
        \copy(a:rgb), 
        \s:Scale_vector(a:delta * g:swatch_step, l:change)
        \)
  return map(new, {k,v -> s:Constrain_value(v, [0,255])})
endfunction
" }}} Transform_rgb ❮
" {{{ Hex_to_RGB ❯
function! s:Hex_to_RGB(hex)
  return map([a:hex[0:1], a:hex[2:3], a:hex[4:5]], 
        \{k,v -> printf('%d', str2nr(v, '16'))}
        \)
endfunction
" }}} Hex_to_RGB ❮
" {{{ RGB_to_hex ❯
function! s:RGB_to_hex(rgb)
  return join(map(a:rgb, {k,v -> printf('%02x', v)}), '')
endfunction
" }}} RGB_to_hex ❮
" {{{ Constrain_value ❯
function! s:Constrain_value(x, range)
  let min = a:range[0] | let max = a:range[1]
  return min([max([a:x, l:min]), l:max])
endfunction
" }}} Constrain_value ❮
" }}} Computations ❮
" {{{ Variables ❯
let s:last_trigger_pos = [0,0]
let s:last_cursor_pos = [0,0]
let s:in_visual = v:false
let s:OG_visual_hidef = ['none', '000000', 'ffffff']
" }}} Variables ❮
" }}} Backend ❮
" {{{ Setup ❯
call Swatch_set_shortcuts([['w','s'],['e','d'],['r','f']])
nnoremap <leader>ss :call Swatch_new_adjustment()<cr>
nnoremap <leader>pt :call Swatch_preview_this()<cr>
" }}} Setup ❮

" vim:tw=78:ts=2:sw=2:et:fdm=marker:
