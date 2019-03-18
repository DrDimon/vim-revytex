# Revytex.vim

Plugin to ease writing sketches and songs using
[revytex](https://github.com/dikurevy/RevyTeX)

This plugin translates a simple and easy writeable fileformat to .tex files.

# Installation

Keybindings supports '.'-repeat with [repeat.vim](https://github.com/tpope/vim-repeat)

# Usage

## FormatSketch
Default keybindings:
~~~~
  nmap sq <Plug>FormatSketch()<CR>
  vmap sq :call FormatSketch()<CR>
~~~~

Examples of rewriting in visual mode:
~~~~
  adf afd asdf 
 
  adf afd asdf 
  adf afd asdf 
  p: adfasdf asdf
  p[adf]: aaaa bbb
~~~~

To:
~~~~
  \scene{adf afd asdf}

  \scene{adf afd asdf
  adf afd asdf}
  \says{P} adfasdf asdf
  \says{P}[adf] aaaa bbb
~~~~

In normal mode the same transformation is done, except it only affect the line with the cursor.
If the cursor is on first line the following is rewritten:
~~~~
  adf afd asdf 
  adf afd asdf 
~~~~

To:
~~~~
  \scene{adf afd asdf}
  adf afd asdf
~~~~

## FormatSong
Default keybindings:
~~~~
  nmap sa <Plug>FormatSong()<CR>
  vmap sa :call FormatSong()<CR>
~~~~

Examples of rewriting in visual mode
~~~~
  AAAAAA
  BBBBBBB

  P:
    CCC
    CCC
  S: DDD
     DDD

  FFFFFFFFFFF
~~~~

To:
~~~~
  \scene{AAAAAA
  BBBBBBB}

  \sings{P}
    CCC
    CCC
  \sings{S} DDD
     DDD

  \scene{FFFFFFFFFFF}
~~~~

As before scenes are not multiline in normal mode.

If the start of visual selection, or cursor in normal mode is in the middle of a \sings{} line, (either 'CCC' lines from the example) the \sings{} tag is still used on the previous line w. ':'

## command :RevytexToSketch & :RevytexToSong
Apply the previous transformations on the whole file, and wrap it in the latex needed to compilable a song or sketch with revytex.

Roles are extracted from the \says{} or \sings{} tags.
Splitting roles with either ' ' ',' '+' or '-' creates multiple roles.
Fx: A+B: => \says{A+B} => creates roles A and B

The user is prompted for title, time, status, author (and melody in songs).

## Configuration
Disable keymaps:
~~~~
  let g:revytex_no_mappings = 1
~~~~

Change default author:
~~~~
  let g:revytex_default_author = 'Preben'
~~~~
