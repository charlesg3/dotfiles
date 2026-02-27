" Vim color file
" Maintainer:   Thorsten Maerz <info@netztorte.de>
" Last Change:  2001 Jul 23
" grey on black
" optimized for TFT panels

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
"colorscheme default
let g:colors_name = "cg3"

" hardcoded colors :
" GUI Comment : #80a0ff = Light blue

" GUI
hi Normal     guifg=Grey100 guibg=Black ctermfg=White ctermbg=Black
hi Search     guifg=Black   guibg=yellow    gui=bold
hi Visual     guifg=black   guibg=yellow    gui=bold
hi Cursor     guifg=Black   guibg=White gui=bold
hi Special    guifg=Orange
hi Comment    guifg=#63B8FF ctermfg=LightBlue cterm=none term=none
hi StatusLine guifg=blue    guibg=white
hi Statement  guifg=Yellow  gui=NONE     ctermfg=Yellow         cterm=NONE
hi Type       term=underline ctermfg=DarkGreen gui=none guifg=Green
hi VertSplit  term=reverse cterm=reverse gui=bold guifg=#707070 guibg=#707070

" numbers and include files and strings
hi Constant   term=NONE ctermfg=red guifg=red
hi Identifier term=NONE ctermfg=cyan cterm=NONE guifg=magenta
" #include
hi PreProc    term=none cterm=NONE ctermfg=magenta guifg=cyan
hi Ignore     ctermfg=Gray cterm=bold guifg=bg
hi Error      term=reverse ctermfg=Gray ctermbg=DarkRed cterm=bold gui=bold guifg=White guibg=Red
hi Todo       term=standout ctermfg=DarkBlue ctermbg=Yellow guifg=Blue guibg=Yellow

" Console
hi Search     ctermfg=Black ctermbg=Red cterm=NONE
hi Visual                   cterm=reverse
hi Cursor     ctermfg=Black ctermbg=Green   cterm=bold
hi Special    ctermfg=Brown
hi StatusLine ctermfg=blue  ctermbg=white

" ── Color palette ───────────────────────────────────────────────────────────
let g:color_green   = '#a3f7bf'   " rgb(163, 247, 191)
let g:color_cyan    = '#5eaecb'   " rgb(94, 174, 203)
let g:color_purple  = '#afb9fa'   " rgb(175, 185, 250)
let g:color_peach   = '#da7b77'   " rgb(218, 123, 119)
let g:color_teal    = '#25c4c6'   " rgb(37, 196, 198)
let g:color_blue    = '#45baff'   " rgb(69, 186, 255)
let g:color_magenta = '#ff0070'   " rgb(255, 0, 112)
let g:color_yellow  = '#ffff00'   " rgb(255, 255, 0)
let g:color_orange  = '#ffa100'   " rgb(255, 161, 0)

" only for vim 5
if has("unix")
  if v:version<600
    highlight Normal  ctermfg=Grey  ctermbg=Black   cterm=NONE  guifg=Grey80      guibg=Black   gui=NONE
    highlight Search  ctermfg=Black ctermbg=Red cterm=bold  guifg=Black       guibg=Red gui=bold
    highlight Visual  ctermfg=Black ctermbg=yellow  cterm=bold  guifg=Grey25            gui=bold
    highlight Special ctermfg=LightBlue         cterm=NONE  guifg=LightBlue         gui=NONE
    highlight Comment ctermfg=Cyan          cterm=NONE  guifg=LightBlue         gui=NONE
  endif
endif

