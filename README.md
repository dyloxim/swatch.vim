# Swatch.vim 0.1

Swatch is a plugin to make working with hexadecimal color codes and colorschemes easier.

![adjust color schemes](https://media.giphy.com/media/SSc9tHaMEPPw7XYuTF/giphy.gif)

## Requirements:

* nvim instance capable of displaying true color.
* an nvim interface that correctly interprets meta key chords (ie. allows mappings like `nnoremap <m-a> :echo 'hi'`)

## Default mappings

```
" New adjustment: identify hl group under cursor and take you to new
" buffer where its attributes can be adjusted
nnoremap <leader>ss :call Swatch_new_adjustment()

" Preview this: highlight the current word (color name or hex code) with
" the color it represents
nnoremap <leader>pt :call Swatch_preview_this()
```

how to interact with color under the cursor:

![meta chord](https://i.imgur.com/WlGkGne.jpg)

This image shows the key chord that you would press to _increase_ the _first_ channel.

The top row of keys corresponds to an increase in a channel, the bottom row corresponds to a decrease.

The columns correspond to the three channels, first red, then green then blue.

So meta-w increases red, meta-f decreases blue.

I find it fairly intuitive to use.

## Usage
### For altering/making colorschemes
calling the new adjustment function opens a file containing adjustments to the currently active colorscheme, in the directory specified by `g:swatch_dir`. By default this path is: `~/.config/nvim/plugins/swatch/`.

You can change the location of the swatch directory by putting `let g:swatch_dir = 'path/to/your/desired/location/` (trailing forward slash obligatory)

to load alterations to a colorscheme on startup add the line `call Swatch_load('$name_of_colorscheme')` either instead of, or after calling `colo $name_of_colorscheme`.

### For working with hexadecimal color codes more generally

previewing and interactively changing color should work straight away.

## Todos

* implement second mode where the channels correspond to hue/saturation/value
* add interface for creating folders of swatches and the ability to link to those swatches, and between other groups
* fix previewing of named colors with upper case letters in the middle of the word
* write help file




