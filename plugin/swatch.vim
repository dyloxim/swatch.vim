" {{{ New_adjustment ❯
function! New_adjustment(...)
  if len(a:) < 5 | let group = Get_group() | else | let group = get(a:, 1) | endif
  let attributes = Get_attributes()
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
    echo [fg, bg, style]
    call append(0, 
          \['"{{{ ' . l:group    ] +
          \['hi ' . l:group      ] +
          \['    \ gui=' . l:style] +
          \['    \ guifg=' . l:fg ] +
          \['    \ guibg=' . l:bg ] +
          \['"}}} ' . l:group    ]
          \)
  normal zMgg
  call search(group)
  normal zv3j
  endif

endfunction
" }}} New_adjustment ❮
" {{{ Get_attributes ❯
function! Get_attributes(group)
  let hlID = hlID(group)
  let [fg, bg, style] = [
        \[
        \synIDattr(hlID, 'bold') == 1 ? 1 : 0, 
        \synIDattr(hlID, 'italic') == 1 ? 1 : 0,
        \(synIDattr(hlID, 'undercurl') == 1 ? 2 :
        \(synIDattr(hlID, 'underline') == 1 ? 1 : 0)
        \)],
        \synIDattr(hlID, 'fg#'),
        \synIDattr(hlID, 'bg#')
        \]
endfunction
" }}} Get_attributes ❮
" {{{ Style_encode ❯
function! Style_encode(style_string)
endfunction
" }}} Style_encode ❮
" {{{ Style_decode ❯
function! Style_decode(tally)
  let style_string =
    \ (tally[0] == 1 ? 'bold,'      : '') .
    \ (tally[1] == 1 ? 'italic,'    : '') .
    \ (tally[2] == 1 ? 'underline,' : '') .
    \ (tally[2] == 2 ? 'undercurl,' : '')
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
  let g:in_visual = get(a:, 2, v:false)

  if a:audit == v:true
    call Audit()
  else
  endif
endfunction
" }}} Adjust_Levels ❮
" {{{ Audit ❯
function! Audit()
  if On('hidef')
    echo 'on hidef'
  elseif g:in_visual == v:true
    echo 'in visual'
  elseif On('hex')
    echo 'on hex'
  else
    echo 'on none'
  endif
endfunction
" }}} Audit ❮
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
function! Get_group()
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
endfunction
" }}} Get_group ❮

" {{{ Variables ❯
let g:in_visual = v:false
let g:swatch_dir = 'Users/Joel/.config/nvim/rc/swatch/'
" }}} Variables ❮

call Set_Shortcuts([['w','s'],['e','d'],['r','f']])
nnoremap <leader>ss :call New_adjustment()<cr>

" hi Normal guibg=#aaaaaa
" #aaaaaa
"

" vim:tw=78:ts=2:sw=2:et:fdm=marker:
