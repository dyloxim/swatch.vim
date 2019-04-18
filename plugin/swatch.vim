" {{{ Alter ❯
function! Adjust_Levels(channel, delta, ...)
  let a:audit = get(a:, 1, v:true)
  let g:in_visual = get(a:, 2, v:false)

  if a:audit == v:true
    call Audit()
  else
  endif
endfunction
" }}} Alter ❮

" {{{ Audit ❯
function! Audit()
  if On('hidef')
    echo 'on hidef'
  elseif g:in_visual == v:true
    echo 'in preview'
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

" {{{ Variables ❯
let g:in_visual = v:false
" }}} Variables ❮

call Set_Shortcuts([['w','s'],['e','d'],['r','f']])

" vim:tw=78:ts=2:sw=2:et:fdm=marker:
