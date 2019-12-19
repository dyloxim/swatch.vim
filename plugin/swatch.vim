" Swatch: a great plugin by Joel Strouts

" {{{ API ❯
" TODO: add interface for managing alteration files (ie. `call Swatch_reset`
" to let the user remove adjustment files they wish to dissavow etc.)
" {{{ Swatch_new_adjustment ❯
function! Swatch_make_alteration()
  let group = s:Get_group('cursor')
  if l:group != ''
    call s:Goto_alterations_buffer()
    normal ggzR
    if search(group, 'n') == 0
      call s:Insert_group(group)
    endif
    call search(group)
    normal zMzv3j
  endif
endfunction
" }}} Swatch_new_adjustment ❮
" {{{ Swatch_adjust_levels ❯
function! Swatch_adjust_levels(channel, delta, ...)
  let s:in_visual = get(a:, 1, v:false)
  let context = s:Get_context()
  if context != 'none'
    if s:in_visual
      if s:Position_valid()
        normal 
        call cursor(s:last_trigger_pos)
        undojoin | call s:Adjust_levels_{context}(a:channel, a:delta)
        undojoin | 
      endif
    else
      call s:Set_last('trigger_pos')
      call s:Adjust_levels_{context}(a:channel, a:delta)
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
  let value = s:Get_value('here')
  call s:Preview_value(value)
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
          \. 'v:true)<cr>' 
    exe 'vnoremap <m-' . a:channels[l:i][1] . '> '
          \. ":<c-u>'>call Swatch_adjust_levels(" . l:i . ',-1,'
          \. 'v:true)<cr>'
  endfor
endfunction
" }}} Swatch_set_shortcuts ❮
" {{{ Swatch_load ❯
function! Swatch_load(...)
  let colorscheme = get(a:, 1, s:Colors_name())
  let group = get(a:, 2, 'none')

  if group == 'none'
    exe 'colo ' . colorscheme
    if filereadable(s:Get_alterations_file())
      exe 'source ' . g:swatch_dir . 'alterations/' . colorscheme . '.vim'
    endif
    if filereadable(s:Get_links_file())
      exe 'source ' . g:swatch_dir . 'alterations/' . colorscheme . '-links.vim'
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
" {{{ Variables ❯
if !exists('g:swatch_step')              | let g:swatch_step = 5                               | endif
if !exists('g:swatch_dir')               | let g:swatch_dir = expand('~/.config/nvim/swatch/') | endif
if !exists('g:swatch_preview_region')    | let g:swatch_preview_region = 'word'                | endif
if !exists('g:swatch_preview_style')     | let g:swatch_preview_style = 'bg'                   | endif
if !exists('g:swatch_enable_on_startup') | let g:swatch_enable_on_startup = v:true             | endif
" }}} Variables ❮
" }}} API ❮
" {{{ Backend ❯
" {{{ Audits ❯
" {{{ Position_valid ❯
function! s:Position_valid()
  if s:in_visual
    if s:Get_last('cursor_pos')[0] == s:Get_current('line')
      return v:true
    else
      return v:false
    endif
  else
    if s:Get_last('trigger_pos')[0] == s:Get_current('line')
      return v:true
    else
      return v:false
    endif
  endif
endfunction
" }}} Position_valid ❮
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
  let key = s:Get_key() | let value = s:Get_value('here')
  let new_value = s:Transform_{key == 'gui' ? 'style' : 'value'}
        \(value, a:channel, a:delta)
  call s:Apply_style(group, key, new_value)
  call s:Replace_hidef(key, new_value)
  if key != 'gui' | call Swatch_preview_this() | endif
endfunction
" }}} Adjust_levels_HIDEF ❮
" {{{ Adjust_levels_HEX ❯
function! s:Adjust_levels_HEX(channel, delta)
  let value = s:Get_value('here')
  let new_value = s:Transform_value(value, a:channel, a:delta)
  call s:Replace_hex(new_value)
  call Swatch_preview_this()
endfunction
" }}} Adjust_levels_HEX ❮
" }}} Adjust_levels ❮
" {{{ Get & Set ❯
" {{{ Get_context ❯
function! s:Get_context()
  if s:On('HIDEF')
    call s:Position_cursor_ON_HIDEF() | return 'HIDEF'
  elseif s:On('HEX')
    call s:Position_cursor_ON_HEX() | return 'HEX'
  elseif s:Has(getline('.'), 'HIDEF')
    call s:Position_cursor_HAS_HIDEF() | return 'HIDEF'
  elseif s:Has(getline('.'), 'HEX')
    call s:Position_cursor_HAS_HEX() | return 'HEX'
  else
    echo 'on nothing'
    return 'none' 
  endif
endfunction
" }}} Get_context ❮
" {{{ Goto_links_buffer ❯
function! s:Goto_links_buffer()
  let links_file_path = s:Get_links_file()
  if s:Swatch_buffer_open()[0]
    let buffer = s:Get_{s:Swatch_buffer_open()[1]}_file()
    exe bufwinnr(l:buffer) . 'wincmd w'
    exe 'edit! ' . l:links_file_path
  else
    wincmd v | wincmd L " | exe '40 wincmd |'
    if !filereadable(links_file_path)
      call s:Init_links_file(links_file_path)
    endif
    exe 'edit ' . links_file_path
  endif
endfunction
" }}} Goto_links_buffer ❮
" {{{ Goto_alterations_buffer ❯
function! s:Goto_alterations_buffer()
  let alterations_file_path = s:Get_alterations_file()
  if s:Swatch_buffer_open()[0]
    let buffer = s:Get_{s:Swatch_buffer_open()[1]}_file()
    exe bufwinnr(l:buffer) . 'wincmd w'
    write!
    exe 'edit! ' . l:alterations_file_path
  else
    wincmd v | wincmd L " | exe '40 wincmd |'
    if !filereadable(alterations_file_path)
      call s:Init_alterations_file(alterations_file_path)
    endif
    exe 'edit ' . alterations_file_path
  endif
endfunction
" }}} Goto_alterations_buffer ❮
" {{{ Get_value_from_name ❯
function! s:Get_value_from_name(name)
  let binary_color = printf('%024b', nvim_get_color_by_name(a:name))
  let hex = join(map([
        \binary_color[0:7],
        \binary_color[8:15], 
        \binary_color[16:23]
        \],
        \{k,v -> printf('%02x', '0b' . v)}), '')
  return hex
endfunction
" }}} Get_value_from_name ❮
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
" {{{ Get_links_file ❯
function! s:Get_links_file()
  return g:swatch_dir . 'alterations/'
        \. s:Colors_name()
        \. '-links.vim'
endfunction
" }}} Get_links_file ❮
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
" {{{ Get_links_template ❯
function! s:Get_links_template()
  let template = 
        \ [''] +
        \ ['" vim:tw=78:ts=2:sw=2:et:fdm=marker:']
  return template
endfunction
" }}} Get_links_template ❮
" {{{ Get_alterations_template ❯
function! s:Get_alterations_template()
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
  let template = 
        \ template +
        \ [''] + 
        \ ['" for a complete list of groups see the file :so $VIMRUNTIME/syntax/hitest.vim'] +
        \ [''] +
        \ ['" vim:tw=78:ts=2:sw=2:et:fdm=marker:']
  return template
endfunction
" }}} Get_alterations_template ❮
" {{{ Get_value ❯
function! s:Get_value(context)
  if a:context == 'here'
    let value = substitute(split(expand('<cWORD>'), '=')[-1], '#', '', 'g')
  elseif a:context == 'elsewhere'
    call cursor(s:last_trigger_pos)
    let value = substitute(split(expand('<cWORD>'), '=')[-1], '#', '', 'g')
    call cursor(s:last_cursor_pos)
  endif
  let value = substitute(value, '[^a-zA-Z0-9,]', '', 'g')
  return substitute(value, ',$', '', '')
endfunction
" }}} Get_value ❮
" {{{ Get_group_chain ❯
function! s:Get_group_chain()
    " what synatx group under the current cursor position are you interested
    " in altering?
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
          \k,v -> printf("%s. %s -> %s -> %s",
          \k+1, v[0], v[1], 
          \(v[1] == v[2] ? "-" : v[2]))
          \})
    echohl Title | echom "Choose highlight group you wish to alter" | echohl None
    let chain = inputlist(l:synlist)
    if l:chain == 0 || l:chain > len(l:synlist)
      return ['', '']
    else
      let child = l:syntaxes[chain-1][1] | let parent = l:syntaxes[chain-1][2] 
      return [l:child, l:parent]
    endif
endfunction
" }}} Get_group_chain ❮
" {{{ Get_group ❯
function! s:Get_group(context)
  if a:context == 'cursor'
    redraw!
    let [child, parent] = s:Get_group_chain()

    redraw!
    if [l:child,l:parent] == ['','']
      redraw!
      echohl Error | echom 'Invalid selection' | echohl None
    elseif l:child == l:parent
      " (no linking)
      echohl Title | echom "Would you like to:" | echohl None
      let group_choice = inputlist([
            \printf("1. alter %s directly, or:", l:child),
            \printf("2. link %s to a new group?", l:child),
            \])
      if l:group_choice == 1 | return l:parent
      elseif l:group_choice == 2
        redraw!
        let link_destination = input(printf(
              \'provide the name of the new group you wish to link to, %s -> ',
              \l:child
              \))
        call s:New_link(l:child, l:link_destination)
        return l:link_destination
      else
        redraw!
        echohl Error | echom 'Invalid selection' | echohl None
        return 0
      endif
      return l:parent
    else
      " child != parent (the group is linked to another one)
      echohl Title
      echom printf("Which group in the highlight chain [%s -> %s] would you like to edit:",
            \l:child,
            \l:parent) 
      echohl None
      let group_choice = inputlist([
            \printf("1. %s : (maintain link)", l:parent),
            \printf("2. %s : (break link)", l:child),
            \printf("3. New Link (break link)")
            \])
      if l:group_choice == 1 
        return l:parent
      elseif l:group_choice == 2
        call s:New_link(l:child, 'NONE')
        return l:child
      elseif l:group_choice == 3
        let link_destination = input(printf('provide the name of 
            \the new group you wish to link to, %s -> ', l:child))
        call s:New_link(l:child, l:link_destination)
        return l:link_destination
      else
        redraw!
        echohl Error | echom 'Invalid selection' | echohl None
        return 0
      endif
    endif
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
" {{{ Get_key ❯
function! s:Get_key()
  return split(expand('<cWORD>'), '=')[0]
endfunction
" }}} Get_key ❮
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
" {{{ New_link ❯
function! s:New_link(origin, destination)
  call s:Goto_links_buffer()
  if search('hi! link ' . a:origin) != 0
    exe 'normal D'
  endif
  call append(0, 
        \['hi! link ' . a:origin . ' ' . a:destination]
        \)
  write
  source %
endfunction
" }}} New_link ❮
" {{{ Insert_group ❯
function! s:Insert_group(group)
  let [style, fg, bg] = s:Get_attributes_string(a:group)
  let [fg, bg] = map([fg, bg],
        \{k,v -> v[0] =~ '\u' ||  v =~ '\v(none|fg|bg)' ? v : '#' . v})
  call append(0, 
        \['" {{{ '       . a:group ] +
        \['hi '          . a:group ] +
        \['    \ gui='   . l:style ] +
        \['    \ guifg=' . l:fg    ] +
        \['    \ guibg=' . l:bg    ] +
        \['" }}} '       . a:group ]
        \)
endfunction
" }}} Insert_group ❮
" {{{ Init_links_file ❯
function! s:Init_links_file(path)
  let template = s:Get_links_template()
  exe '!mkdir -p ' . g:swatch_dir . 'alterations/'
  exe '!touch ' . a:path
  silent call writefile(template, a:path)
endfunction
" }}} Init_links_file ❮
" {{{ Init_alterations_file ❯
function! s:Init_alterations_file(path)
  let template = s:Get_alterations_template()
  exe '!mkdir -p ' . g:swatch_dir . 'alterations/'
  exe '!touch ' . a:path
  silent call writefile(template, a:path)
endfunction
" }}} Init_alterations_file ❮
" {{{ Swatch_buffer_open ❯
function! s:Swatch_buffer_open()
  let alteration_file = g:swatch_dir . 'alterations/'
        \. (exists('g:colors_name') ? g:colors_name : 'default')
        \. '.vim'
  let links_file = g:swatch_dir . 'alterations/'
        \. (exists('g:colors_name') ? g:colors_name : 'default')
        \. '-links.vim'
  if bufwinnr(alteration_file) != -1
    return [v:true, 'alterations']
  elseif bufwinnr(links_file) != -1
    return [v:true, 'links']
  else
    return [v:false]
  endif
endfunction
" }}} Swatch_buffer_open ❮
" }}} Windows & Files ❮
" {{{ Replace / Load / styles ❯
" {{{ Swatch_init ❯
function! s:Swatch_init()
  if g:swatch_enable_on_startup == v:true
    call Swatch_load()
  endif
endfunction
" }}} Swatch_init ❮
" {{{ Replace_hex ❯
function! s:Replace_hex(value)
  let cword = substitute(expand('<cWORD>'), '[^a-zA-Z0-9#]', '', 'g')
  call cursor(s:last_trigger_pos)
  exe s:last_trigger_pos[0] . 's/' . cword . '/' . '#' . a:value
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
  let value = substitute(value, '\v^.*$', '\u\0', '')
  exe 'hi ' . a:group . ' ' . a:key . '=' . value
endfunction
" }}} Apply_style ❮
" {{{ Preview_value ❯
function! s:Preview_value(hex, ...)
  let s:OG_visual_hidef = s:Get_attributes_string('Visual')
  let s:preview_region = get(a:, 1, g:swatch_preview_region)
  let hex = s:Is_color(a:hex) || s:Is_style(a:hex) ? a:hex : '#' . a:hex
  if g:swatch_preview_style == 'fg'
    exe 'hi Visual guifg=' . hex
  elseif g:swatch_preview_style == 'bg'
    exe 'hi Visual guibg=' . hex
  elseif g:swatch_preview_style == 'both'
    exe 'hi Visual guifg=' . hex
    exe 'hi Visual guibg=' . hex
  endif

  if s:preview_region =~ 'screen'
    normal! HVL
  elseif s:preview_region =~ 'para'
    normal! vap
  elseif s:preview_region =~ 'WORD'
    normal! viW
  elseif s:preview_region =~ 'word'
    normal! viw
  endif

  call s:Set_last('cursor_pos')

  augroup Swatch_Cursor
    au!
    au CursorMoved * call s:Reset_visual()
  augroup END
endfunction
" }}} Preview_value ❮
" {{{ Reset_visual ❯
function! s:Reset_visual()
  if s:Get_last('cursor_pos') != s:Get_current('pos')
    normal 
    call cursor(s:last_trigger_pos)
    call Swatch_load(s:Colors_name(), 'Visual')
    augroup Swatch_Cursor
      au!
    augroup END
  endif
endfunction
" }}} Reset_visual ❮
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
  normal lBEb2l
endfunction
" }}} Position_cursor_ON_HIDEF ❮
" {{{ Position_cursor_ON_HEX ❯
function! s:Position_cursor_ON_HEX()
  normal lb2l
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
  let tally[0] = (tally[0] + 2) % 2 
  let tally[1] = (tally[1] + 2) % 2
  let tally[2] = (tally[2] + 3) % 3
  return s:Style_decode(tally)
endfunction
" }}} Transform_style ❮
" {{{ Transform_value ❯
function! s:Transform_value(value, channel, delta)
  if nvim_get_color_by_name(a:value) == -1
    let rgb = s:Hex_to_RGB(a:value)
    let new_rgb = s:Transform_rgb(rgb, a:channel, a:delta)
    let new_value = s:RGB_to_hex(new_rgb)
  else
    let new_value = s:Get_value_from_name(a:value)
  endif
  return new_value
endfunction
" }}} Transform_value ❮
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
call s:Swatch_init()
nnoremap <leader>ss :call Swatch_make_alteration()<cr>
nnoremap <leader>pt :call Swatch_preview_this()<cr>
" }}} Setup ❮


" vim:tw=78:ts=2:sw=2:et:fdm=marker:
