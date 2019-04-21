" Swatch: a great plugin by Joel Strouts

" {{{ API ❯
" {{{ New_adjustment ❯
function! New_adjustment(...)
  if len(a:) < 5 | let group = Get_group('cursor') | else | let group = get(a:, 1) | endif
  if group != ''
    let attributes = Get_attributes_string(group)
    let file_path = g:swatch_dir . 'alterations/'
          \. (exists('g:colors_name') ? g:colors_name : 'default')
          \. '.vim'
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
" {{{ Adjust_Levels ❯
function! Adjust_Levels(channel, delta, ...)
  let a:audit = get(a:, 1, v:true)
  let s:in_visual = get(a:, 2, v:false)

  if a:audit == v:true
    call Audit(a:channel, a:delta)
  else
    if s:context == 'hidef'
      let group = Get_group('hidef')
      call Position_cursor_hidef()
      let key = Get_hidef('key') | let value = Get_hidef('value')
      if key == 'gui'
        let new_style_string = Transform_style(value, a:channel, a:delta)
        call Apply_style(group, key, new_style_string)
        call Replace_hidef(key, new_style_string)
      else
        if value[0] =~ '\u' 

        else
          let new_hex = Transform_hex(value, a:channel, a:delta)
          call Apply_style(group, key, new_hex)
          call Replace_hidef(key, new_hex)
        endif
      endif
    elseif s:context == 'hex'
      call Position_cursor_hex()
      let hex = Get_hex('one') | let new_hex = Transform_hex(hex, a:channel, a:delta)
      call Replace_hex(hex, new_hex)
      call Preview_hex(new_hex)
    elseif s:context == 'in_visual'
      let hex = Get_hex('one-two') | let new_hex = Transform_hex(hex, a:channel, a:delta)
      call Replace_hex(hex, new_hex)
      call Preview_hex(new_hex)
    endif
  endif
endfunction
" }}} Adjust_Levels ❮
" {{{ Preview_this ❯
function! Preview_this()
  let s:OG_visual_hidef = Get_attributes_string('Visual')
  call Position_cursor('hex')
  let hex = Get_hex('one')
  call Preview_hex(hex, 'word')
endfunction
" }}} Preview_this ❮
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
" {{{ Variables ❯
let g:swatch_step = 5
let g:swatch_dir = '/Users/Joel/.config/nvim/rc/swatch/'
let g:preview_region = 'word'
let g:preview_style = 'bg'
" }}} Variables ❮
" }}} API ❮

" {{{ Backend ❯
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
" {{{ Audits ❯
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
  if Get_last('trigger_pos')[0] == Get_current('line')
    undojoin | call Adjust_Levels(a:channel, a:delta, v:false)
  else
    call Set_last('trigger_pos')
    call Adjust_Levels(a:channel, a:delta, v:false, 'hidef')
  endif
endfunction
" }}} Audit_for_hidef ❮
" {{{ Audit_for_hex ❯
function! Audit_for_hex(channel, delta)
  let s:OG_visual_hidef = Get_attributes_string('Visual')
  echom join(s:OG_visual_hidef, ' ')
  call Adjust_Levels(a:channel, a:delta, v:false, 'hex')
endfunction
" }}} Audit_for_hex ❮
" {{{ Audit_for_preview ❯
function! Audit_for_preview(channel, delta)
  if Get_last('cursor_pos')[0] == Get_current('pos')[0]
    undojoin | call Adjust_Levels(a:channel, a:delta, v:false, 'in_visual')
  else
    " echo 'No color selected'
  endif
endfunction
" }}} Audit_for_preview ❮
" }}} Audits ❮
" {{{ Other ❯
" {{{ Replace_hex ❯
function! Replace_hex(old, new)
  exe s:last_trigger_pos[0] . 's/' . a:old . '/' . a:new
  call cursor(s:last_trigger_pos)
endfunction
" }}} Replace_hex ❮
" {{{ Preview_hex ❯
function! Preview_hex(hex, ...)
  let a:preview_region = get(a:, 1, g:preview_region)
  
  if g:preview_style == 'fg'
    exe 'hi Visual guifg=#' . a:hex
  elseif g:preview_style == 'bg'
    exe 'hi Visual guibg=#' . a:hex
  elseif g:preview_style == 'both'
    exe 'hi Visual guifg=#' . a:hex
    exe 'hi Visual guibg=#' . a:hex
  endif

  if a:preview_region == 'screen'
    normal! HVL
  elseif a:preview_region == 'para'
    normal! vap
  elseif a:preview_region == 'WORD'
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
    echo s:OG_visual_hidef
    exe 'hi Visual guifg=#' . s:OG_visual_hidef[0]
          \. ' guibg=#' . s:OG_visual_hidef[1]
          \. ' gui=' . s:OG_visual_hidef[2]
    augroup Swatch
      au!
    augroup END
  endif
endfunction
" }}} Reset_visual ❮
" {{{ Get_hex ❯
function! Get_hex(context)
  if a:context == 'one-two'
    call cursor(s:last_trigger_pos)
    let hex = expand('<cword>')[-6:]
    call cursor(s:last_cursor_pos)
  elseif a:context == 'one'
    let hex = expand('<cword>')[-6:]
  endif
  return hex
endfunction
" }}} Get_hex ❮
" {{{ Swatch_load ❯
function! Swatch_load(colorscheme)
  exe 'colo ' . a:colorscheme
  if filereadable(g:swatch_dir . 'alterations/' . a:colorscheme . '.vim')
    exe 'source ' . g:swatch_dir . 'alterations/' . a:colorscheme . '.vim'
  endif
endfunction
" }}} Swatch_load ❮
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
" {{{ Insert_group ❯
function! Insert_group(group, attributes)
  let [fg, bg, styles] = a:attributes
  let [fg, bg] = map([fg, bg],
        \{k,v -> v[0] =~ '\u' ||  v == 'none' ? v : '#' . v})
  call append(0, 
        \['" {{{ '        . a:group ] +
        \['hi '          . a:group ] +
        \['    \ gui='   . l:styles] +
        \['    \ guifg=' . l:fg    ] +
        \['    \ guibg=' . l:bg    ] +
        \['" }}} '        . a:group ]
        \)
endfunction
" }}} Insert_group ❮
" {{{ Get_attributes_string ❯
function! Get_attributes_string(group)
  redir => group_information | silent exe "hi" a:group | redir END
  let attributes = filter(split(l:group_information), {
        \k,v -> match(v, 'gui') != '-1'
        \})
  let [fg, bg, style] = ['none', 'none', 'none']
  for attr in attributes
    if attr =~ '\vguifg\=.+' | let fg    = attr[6:] | endif
    if attr =~ '\vguibg\=.+' | let bg    = attr[6:] | endif
    if attr =~ '\vgui\=.+'   | let style = attr[4:] | endif
  endfor
  return map([fg, bg, style], {k,v -> substitute(v, '#\+', '', 'g')})
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
    let [fg, bg, style] = Get_attributes_string(group)
  let [fg, bg] = map([fg, bg], 
        \{k,v -> v[0] =~ '\u' ||  v == 'none' ? v : '#' . v})
    let template = template +
          \['"{{{ '        . group] +
          \['hi '          . group] +
          \['    \ gui='   . style] +
          \['    \ guifg=#' . fg   ] +
          \['    \ guibg=#' . bg   ] +
          \['"}}} '        . group]
  endfor
  let template = template + ['" vim:tw=78:ts=2:sw=2:et:fdm=marker:']
  return template
endfunction
" }}} Get_template ❮
" {{{ Replace_hidef ❯
function! Replace_hidef(key, value)
  exe 's/' . expand('<cWORD>') . '/' . a:key . '=' 
        \. (len(a:key) > 3 ? '#' : '') . a:value
  call cursor(s:last_cursor_pos)
endfunction
" }}} Replace_hidef ❮
" {{{ Apply_style ❯
function! Apply_style(group, key, value)
  exe 'hi ' . a:group . ' ' . a:key . '=' . (len(a:key) > 3 ? '#' : '') . a:value
endfunction
" }}} Apply_style ❮
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
" {{{ Position_cursor ❯
function! Position_cursor(context)
  if a:context == 'hex'
    call Set_last('trigger_pos')
  elseif a:context == 'in_visual'
    call cursor(s:last_trigger_pos)
  endif
endfunction
" }}} Position_cursor ❮
" {{{ Position_cursor_hidef ❯
function! Position_cursor_hidef()
  let cWORD = expand('<cWORD>')
  if cWORD =~ '\vgui(fg|bg)?\=(#[a-fA-F0-9]{6}|(#*)?\w+)'
    normal Ebl
  else
    call search('\vgui(fg|bg)?\=') | normal Ebl
  endif
  call Set_last('cursor_pos')
endfunction
" }}} Position_cursor_hidef ❮
" {{{ Position_cursor_hex ❯
function! Position_cursor_hex(...)
  call Set_last('trigger_pos')
endfunction
" }}} Position_cursor_hex ❮
" {{{ Position_cursor_in_visual ❯
function! Position_cursor_preview(...)
  let a:arg_name = get(a:, 1, [default value])
endfunction
" }}} Position_cursor_preview ❮
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
" }}} Other ❮
" {{{ Variables ❯
let s:last_trigger_pos = [0,0]
let s:last_cursor_pos = [0,0]
let s:in_visual = v:false
let s:OG_visual_hidef = ['000000', 'ffffff', 'none']
" }}} Variables ❮
" }}} Backend ❮

" {{{ Default Setup ❯
call Set_Shortcuts([['w','s'],['e','d'],['r','f']])
nnoremap <leader>ss :call New_adjustment()<cr>
nnoremap <leader>pt :call Preview_this()<cr>
" }}} Setup ❮

" vim:tw=78:ts=2:sw=2:et:fdm=marker:
