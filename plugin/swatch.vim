" Swatch: a great plugin by Joel Strouts

" {{{ API ❯
" {{{ New_adjustment ❯
function! New_adjustment(...)
  if len(a:) < 5 | let group = Get_group('cursor') | else | let group = get(a:, 1) | endif
  if group != ''
    let attributes = Get_attributes_string(group)
    let file_path = Get_alterations_file()
    if Swatch_Buffer_Open()
      exe bufwinnr(file_path) . 'wincmd w'
    else
      wincmd v | wincmd L | exe '50 wincmd |'
      if !filereadable(file_path)
        call Init_alterations_file(file_path)
      endif
      exe 'edit ' . file_path
    endif
    silent if !search(l:group, 'n')
      call Insert_group(group, attributes)
    endif
    normal zMgg
    call search(group)
    normal zv3j
  endif
endfunction
" }}} New_adjustment ❮
" {{{ Adjust_levels ❯
function! Adjust_levels(channel, delta, ...)
  let a:audit = get(a:, 1, v:true)
  let s:in_visual = get(a:, 2, v:false)

  if a:audit == v:true | call Audit(a:channel, a:delta)
  else " audit already performed
    if s:context == 'hidef'
      call Set_last('trigger_pos')
      call Adjust_levels_HIDEF(a:channel, a:delta)
    elseif s:context == 'hex'
      call Set_last('trigger_pos')
      call Adjust_levels_HIDEF(a:channel, a:delta)
    elseif s:context == 'in_visual'
      call Adjust_levels_IN_VISUAL(a:channel, a:delta)
    endif
  endif
endfunction
" }}} Adjust_levels ❮
" {{{ Preview_this ❯
function! Preview_this()
  call Position_cursor('hex')
  let hex = Get_hex('here')
  call Preview_hex(hex, 'word')
endfunction
" }}} Preview_this ❮
" {{{ Set_Shortcuts ❯
function! Set_Shortcuts(channels)
  for i in range(0,2)
    exe 'nnoremap <m-' . a:channels[l:i][0] . '> '
          \. ':call Adjust_levels(' . l:i . ',1)<cr>'
    exe 'nnoremap <m-' . a:channels[l:i][1] . '> '
          \. ':call Adjust_levels(' . l:i . ',-1)<cr>'
    exe 'vnoremap <m-' . a:channels[l:i][0] . '> '
          \. ":<c-u>'>call Adjust_levels(" . l:i . ',1,'
          \. 'v:true, v:true)<cr>' 
    exe 'vnoremap <m-' . a:channels[l:i][1] . '> '
          \. ":<c-u>'>call Adjust_levels(" . l:i . ',-1,'
          \. 'v:true, v:true)<cr>'
  endfor
endfunction
" }}} Set_Shortcuts ❮
" {{{ Variables ❯
let g:swatch_step = 5
let g:swatch_dir = '/Users/Joel/.config/nvim/rc/swatch/'
let g:preview_region = 'word'
let g:preview_style = 'bg'
" }}} Variables ❮
" }}} API ❮

" {{{ Backend ❯
" {{{ Audits ❯
" {{{ Audit ❯
function! Audit(channel, delta)
  if s:in_visual == v:true
    let s:context = 'in_visual' | call Audit_IN_VISUAL(a:channel, a:delta)
  elseif On('hidef')
    call Position_cursor_ON_HIDEF()
    let s:context = 'hidef' | call Audit_HIDEF(a:channel, a:delta)
  elseif On('hex')
    call Position_cursor_ON_HEX()
    let s:context = 'hex' | call Audit_HEX(a:channel, a:delta)
  elseif Has(getline('.'), 'hidef')
    call Position_cursor_HAS_HIDEF()
    let s:context = 'hidef' | call Audit_HIDEF(a:channel, a:delta)
  elseif Has(getline('.'), 'hex')
    call Position_cursor_HAS_HEX()
    let s:context = 'hex' | call Audit_HEX(a:channel, a:delta)
  else
    echo 'on nothing'
  endif
endfunction
" }}} Audit ❮
" {{{ Audit_HIDEF ❯
function! Audit_HIDEF(channel, delta)
  if Get_last('trigger_pos')[0] == Get_current('line')
    undojoin | call Adjust_levels_HIDEF(a:channel, a:delta)
  else
    call Set_last('trigger_pos')
    call Adjust_levels_HIDEF(a:channel, a:delta)
  endif
endfunction
" }}} Audit_HIDEF ❮
" {{{ Audit_HEX ❯
function! Audit_HEX(channel, delta)
  call Set_last('trigger_pos')
  call Adjust_levels_HEX(a:channel, a:delta)
endfunction
" }}} Audit_HEX ❮
" {{{ Audit_IN_VISUAL ❯
function! Audit_IN_VISUAL(channel, delta)
  if Get_last('cursor_pos')[0] == Get_current('pos')[0]
    undojoin | call Adjust_levels_IN_VISUAL(a:channel, a:delta)
  else
    echo 'No color selected'
  endif
endfunction
" }}} Audit_IN_VISUAL ❮
" }}} Audits ❮
" {{{ Adjust_levels ❯
" {{{ Adjust_levels_HIDEF ❯
function! Adjust_levels_HIDEF(channel, delta)
  let group = Get_group('hidef')
  let key = Get_hidef('key') | let value = Get_hidef('value')
  if key == 'gui'
    let new_style_string = Transform_style(value, a:channel, a:delta)
    call Apply_style(group, key, new_style_string)
    call Replace_hidef(key, new_style_string)
  else " key is fg or bg
    if value[0] =~ '\u' 
      let value = Get_hex_from_name(value)
    endif
    let new_hex = Transform_hex(value, a:channel, a:delta)
    call Apply_style(group, key, new_hex)
    call Replace_hidef(key, new_hex)
  endif
endfunction
" }}} Adjust_levels_HIDEF ❮
" {{{ Adjust_levels_HEX ❯
function! Adjust_levels_HEX(channel, delta)
  let old = Get_hex('here') | let new = Transform_hex(old, a:channel, a:delta)
  let name_color = nvim_get_color_by_name(old)
  if name_color != -1
    let new = Get_hex_from_name(old)
    call Replace_hex(old, '#' . new)
  else
    call Replace_hex(old, new)
  endif
  call Preview_hex(new)
endfunction
" }}} Adjust_levels_HEX ❮
" {{{ Adjust_levels_IN_VISUAL ❯
function! Adjust_levels_IN_VISUAL(channel, delta)
  let hex = Get_hex('elsewhere') | let new_hex = Transform_hex(hex, a:channel, a:delta)
  call Replace_hex(hex, new_hex)
  call Preview_hex(new_hex)
endfunction
" }}} Adjust_levels_IN_VISUAL ❮
" }}} Adjust_levels ❮
" {{{ Get & Set ❯
" {{{ Get_hex_from_name ❯
function! Get_hex_from_name(name)
  let binary_color = printf('%024b', nvim_get_color_by_name(a:name))
  echo binary_color
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
function! Get_attributes_string(group)
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
function! Get_style_tally(group)
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
" }}} Get_attributes_tally ❮
" {{{ Get_alterations_file ❯
function! Get_alterations_file()
  return g:swatch_dir . 'alterations/'
        \. Colors_name()
        \. '.vim'
endfunction
" }}} Get_alterations_file ❮
" {{{ Get_alterations ❯
function! Get_alterations()
  if filereadable(Get_alterations_file())
    let list = filter(readfile(Get_alterations_file()),
          \{k,v -> v[0] == '"' ? v:false : v:true})
    let alterations = map(copy(list), 
          \{k,v -> k % 4 == 0 ? 
          \[split(list[k])[1], 
          \split(list[k+1], '=')[1],
          \split(list[k+2], '=')[1],
          \split(list[k+3], '=')[1]] :
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
function! Get_template()
  let template = ['"↓ Difficult to identify groups ↓']
  for group in [
        \'FoldColumn', 'Cursor', 'VertSplit',
        \'Folded', 'Visual', 'Search',
        \'IncSearch', 'LineNR', 'CursorLineNR',
        \'CursorLine', 'SpellBad', 'SpellCap',
        \'SpellRare', 'SpellLocal', 'NonText',
        \'MatchParen']
    let [style, fg, bg] = Get_attributes_string(group)
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
  let template = template + ['" vim:tw=78:ts=2:sw=2:et:fdm=marker:']
  return template
endfunction
" }}} Get_template ❮
" {{{ Get_hex ❯
function! Get_hex(context)
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
    return choice == 0 ? '' : l:syntaxes[choice-1][2]
  elseif a:context == 'hidef'
    call Move_cursor([0,1])
    let line_num = search('\vhi(light)? \w+', 'bn')
    call Move_cursor([0,-1])
    let tokens = split(getline(line_num))
    return filter(copy(tokens),
          \{k,v -> k == 0 ? v:false : (tokens[k-1] =~ '\vhi(light)?' ? v:true : v:false)})[0]
  endif
endfunction
" }}} Get_group ❮
" {{{ Get_hidef ❯
function! Get_hidef(attr)
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
function! Colors_name(...)
  return (exists('g:colors_name') ? g:colors_name : 'default')
endfunction
" }}} Colors_name ❮
" {{{ Cursor_char ❯
function! Cursor_char()
  return getline('.')[col('.')-1]
endfunction
" }}} Cursor_char ❮
" {{{ Get_last ❯
function! Get_last(value)
  if a:value == 'trigger_pos'
    return s:last_trigger_pos
  elseif a:value == 'cursor_pos'
    return s:last_cursor_pos
  endif
endfunction
" }}} Get_last ❮
" {{{ Set_last ❯
function! Set_last(value)
  if a:value == 'trigger_pos'
    let s:last_trigger_pos = [line('.'),col('.')]
  elseif a:value == 'cursor_pos'
    let s:last_cursor_pos = [line('.'),col('.')]
  endif
endfunction
" }}} Set_last ❮
" {{{ Get_current ❯
function! Get_current(thing)
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
function! Insert_group(group, attributes)
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
function! Init_alterations_file(path)
  let template = Get_template()
  exe '!mkdir -p ' . g:swatch_dir . 'alterations/'
  exe '!touch ' . a:path
  silent call writefile(template, a:path)
endfunction
" }}} Init_alterations_file ❮
" {{{ Swatch_Buffer_Open ❯
function! Swatch_Buffer_Open()
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
function! Replace_hex(old, new)
  exe s:last_trigger_pos[0] . 's/' . a:old . '/' . a:new
  call cursor(s:last_trigger_pos)
endfunction
" }}} Replace_hex ❮
" {{{ Replace_hidef ❯
function! Replace_hidef(key, value)
  exe 's/' . expand('<cWORD>') . '/' . a:key . '=' 
        \. (len(a:key) > 3 ? '#' : '') . a:value
  call cursor(s:last_cursor_pos)
endfunction
" }}} Replace_hidef ❮
" {{{ Apply_style ❯
function! Apply_style(group, key, value)
  let value =  a:value =~ '\u' || 
        \a:value =~ '\v(none|fg|bg|bold|italic|underline|undercurl|reverse)' ?
        \ a:value :
        \ '#' . a:value
  let value = substitute(value, '\v^(.*)$', '\u\1', '')
  exe 'hi ' . a:group . ' ' . a:key . '=' . value
endfunction
" }}} Apply_style ❮
" {{{ Preview_hex ❯
function! Preview_hex(hex, ...)
  let s:OG_visual_hidef = Get_attributes_string('Visual')
  let a:preview_region = get(a:, 1, g:preview_region)
  let hex =  a:hex =~ '\u' || a:hex =~ '\v(none|fg|bg)' ?
        \ a:hex :
        \ '#' . a:hex

  if g:preview_style == 'fg'
    exe 'hi Visual guifg=' . hex
  elseif g:preview_style == 'bg'
    exe 'hi Visual guibg=' . hex
  elseif g:preview_style == 'both'
    exe 'hi Visual guifg=' . hex
    exe 'hi Visual guibg=' . hex
  endif

  if a:preview_region == 'screen'
    normal! HVL
  elseif a:preview_region == 'para'
    normal! vap
  elseif a:preview_region ==# 'WORD'
    normal! viW
  elseif a:preview_region == 'word'
    normal viw
  endif

  augroup Swatch
    au!
    au CursorMoved * call Reset_visual()
  augroup END

  call Set_last('cursor_pos')
endfunction
" }}} Preview_hex ❮
" {{{ Reset_visual ❯
function! Reset_visual()
  if Get_last('cursor_pos') != Get_current('pos')
    call Swatch_load(Colors_name(), 'Visual')
    augroup Swatch
      au!
    augroup END
  endif
endfunction
" }}} Reset_visual ❮
" {{{ Swatch_load ❯
function! Swatch_load(...)
  let colorscheme = get(a:, 1, Colors_name()) | let group = get(a:, 2, 'none')

  if group == 'none'
    exe 'colo ' . colorscheme
    if filereadable(Get_alterations_file())
      exe 'source ' . g:swatch_dir . 'alterations/' . colorscheme . '.vim'
    endif
  else | let group = get(a:, 2)
    let index = index(map(Get_alterations(), {k,v -> v[0]}), group)
    if index == -1
      let hidef = ['Visual'] + s:OG_visual_hidef
    else
      let hidef = Get_alterations()[index]
    endif
    call Apply_style(hidef[0], 'gui', hidef[1])
    call Apply_style(hidef[0], 'guifg', hidef[2])
    call Apply_style(hidef[0], 'guibg', hidef[3])
  endif
endfunction
" }}} Swatch_load ❮
" }}} Replace / Load styles ❮
" {{{ Cursor ❯
" {{{ Has ❯
function! Has(line, feature)
  if a:feature == 'hidef'
    if a:line =~ '\vgui(fg|bg)?\=' | return v:true | else | return v:false | endif
  elseif a:feature == 'hex'
    if a:line =~ '\v#[a-fA-F0-9]{6}' | return v:true | else | return v:false | endif
  endif
endfunction
" }}} Has ❮
" {{{ On ❯
function! On(feature)
  let cword = expand('<cWORD>')
  if a:feature == 'hidef'
    if cword =~ '\vgui(fg|bg)?\=' | return v:true | else | return v:false | endif
  elseif a:feature == 'hex'
    if cword =~ '\v#[a-fA-F0-9]{6}' ||
          \ nvim_get_color_by_name(cword) != -1
      return v:true
    else
      return v:false
    endif
  endif
endfunction
" }}} On ❮
" {{{ Position_cursor_ON_HIDEF ❯
function! Position_cursor_ON_HIDEF()
  let cword = expand('<cword>')
  if cword =~ 'gui'
    normal Ebl
  else
    if Cursor_char() != cword[-1] && col('.') != col('$') - 1
      call search('\v(>)\@=', '')
    endif
    normal bl
  endif
endfunction
" }}} Position_cursor_ON_HIDEF ❮
" {{{ Position_cursor_ON_HEX ❯
function! Position_cursor_ON_HEX()
  let cword = expand('<cword>')
  if cword =~ '#' 
    if Cursor_char() != '#'
    else
      normal l
    endif
  else
    if Cursor_char() != cword[-1] && col('.') != col('$') - 1
      call search('\v(>)\@=', '')
    endif
    normal bl
  endif
endfunction
" }}} Position_cursor_ON_HEX ❮
" {{{ Position_cursor_HAS_HIDEF ❯
function! Position_cursor_HAS_HIDEF()
  call search('=')
  call Position_cursor_ON_HIDEF()
endfunction
" }}} Position_cursor_HAS_HIDEF ❮
" {{{ Position_cursor_HAS_HEX ❯
function! Position_cursor_HAS_HEX()
  call search('#') | normal l
endfunction
" }}} Position_cursor_HAS_HEX ❮
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
" }}} Cursor ❮
" {{{ Computations ❯
" {{{ Style_encode ❯
function! Style_encode(style_string)
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
function! Style_decode(tally)
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
function! Transform_style(style_string, channel, delta)
  let tally = Style_encode(a:style_string)
  let change = [[1,0,0],[0,1,0],[0,0,1]][a:channel]
  let tally = VectorAdd(
        \copy(l:tally), 
        \ScaleVector(a:delta/abs(a:delta), l:change)
        \)
  let tally = VectorAdd(tally, [2,2,3])
  let tally[0] = tally[0] % 2 | let tally[1] = tally[1] % 2
  let tally[2] = tally[2] % 3
  return Style_decode(tally)
endfunction
" }}} Transform_style ❮
" {{{ Transform_hex ❯
function! Transform_hex(hex, channel, delta)
  let rgb = Hex_to_RGB(a:hex)
  let new_rgb = Transform_rgb(rgb, a:channel, a:delta)
  let new_hex = RGB_to_hex(new_rgb)
  return new_hex
endfunction
" }}} Transform_hex ❮
" {{{ Transform_rgb ❯
function! Transform_rgb(rgb, channel, delta)
  let change = map([0,1,2], {k, v -> v == a:channel ? 1 : 0})
  let new = VectorAdd(
        \copy(a:rgb), 
        \ScaleVector(a:delta * g:swatch_step, l:change)
        \)
  return map(new, {k,v -> Constrain_value(v, [0,255])})
endfunction
" }}} Transform_rgb ❮
" {{{ Hex_to_RGB ❯
function! Hex_to_RGB(hex)
  return map([a:hex[0:1], a:hex[2:3], a:hex[4:5]], 
        \{k,v -> printf('%d', str2nr(v, '16'))}
        \)
endfunction
" }}} Hex_to_RGB ❮
" {{{ RGB_to_hex ❯
function! RGB_to_hex(rgb)
  return join(map(a:rgb, {k,v -> printf('%02x', v)}), '')
endfunction
" }}} RGB_to_hex ❮
" {{{ Constrain_value ❯
function! Constrain_value(x, range)
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

" {{{ Default Setup ❯
call Set_Shortcuts([['w','s'],['e','d'],['r','f']])
nnoremap <leader>ss :call New_adjustment()<cr>
nnoremap <leader>pt :call Preview_this()<cr>
" }}} Setup ❮

" vim:tw=78:ts=2:sw=2:et:fdm=marker:
