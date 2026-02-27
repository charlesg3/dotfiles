
"Navigation:
"gg   - beginning of file
"G    - end of file
"^    - beginning of line
"$    - end of line
"
"ctrl+j/k = move line up/down
"shift+j/k = nav 5 lines at a time
"Folding:
"zz   - folding on
"zR   - open all folds
"zo   - open current fold
"zc   - close current fold
"
"Search/Replace:
"%s/\n\s*\(word\)/\1/gc - replace /nspaces word with just word
"
set nowritebackup

set mouse-=a

set backupdir=/tmp
set ss=1                        " Nice sidescroll set siso=9                      " Even nicer sidescroll ;)
set nowrap                      " dont wrap lines
set sm                          " show matching paren
set ww=<,>,[,],h,l,b,s,~        " normal cursor movement
set guioptions-=T               " no toolbar 
set background=dark
set novisualbell

"let $NVIM_TUI_ENABLE_TRUE_COLOR=1
hi normal   ctermfg=white  ctermbg=black guifg=white  guibg=black
hi nontext  ctermfg=blue   ctermbg=black guifg=blue   guibg=black

filetype on                     " understand the file type
filetype plugin indent on
"set guifont=-rfx-courier-medium-r-*-*-12-*-*-*-*-*-*-5
"set fileencodings=utf-8,iso-8859-5 "default to utf-8 encoding

set tabstop=4                   " 4 spaces for tabs
set softtabstop=4               " tab causes indent
set shiftwidth=4                " 4 spaces
set expandtab                   " spaces instead of tabs

" Ctrl-P with capital p, ctrl-p is previous buffer
set nocp
execute pathogen#infect()
let g:ctrlp_map = '<S-C-O>'

"autocmd BufEnter * lcd %:p:h   " change to directory of current file automatically (put in _vimrc)

let Tlist_Process_File_Always = 1
let Tlist_Show_One_File = 1
let Tlist_Show_Menu = 1
let Tlist_Use_SingleClick = 1
let Tlist_Auto_Highlight_Tag = 1
let Tlist_Close_On_Select = 1
let Tlist_Auto_Update = 1
let Tlist_GainFocus_On_ToggleOpen = 1
let Tlist_Highlight_Tag_On_BufEnter = 1
let Tlist_Compact_Format = 1

let g:clj_paren_rainbow = 1


" autocmd BufEnter * TlistUpdate   " update taglist
" autocmd BufEnter * call DoWordComplete()
"noremap <LeftRelease> "+y<LeftRelease>

set cinkeys=0{,0},:,0#,!<Tab>,<Return>,!^F

autocmd FileType python,c,cpp,h,hpp,slang set cindent expandtab
autocmd FileType make,css,eruby,html set noexpandtab shiftwidth=4
autocmd FileType javascript,html set expandtab shiftwidth=2
autocmd FileType plaintex set wrap!

syntax on

syntax enable                      " enable syntax highlighting
set previewheight=12               " set gdb console initial height

set viminfo=/10,'10,r/mnt/zip,r/mnt/floppy,f0,h,\"100

set wildmode=list:longest,full

set showmode
set showcmd

set hlsearch
set incsearch
set ignorecase
set smartcase


"Key Mappings
"nnoremap <C-N> :next<CR>
"nnoremap <C-P> :prev<CR>

"Switch Buffers with c-n and c-p
map <C-n> :bn!<CR>
map <C-p> :bp!<CR>

" (GUI) Live line reordering (very useful)
nnoremap <silent> <C-S-k> :move .-2<CR>|
nnoremap <silent> <C-S-j> :move .+1<CR>|
vnoremap <silent> <S-C-K> :move '<-2<CR>gv|
vnoremap <silent> <S-C-J> :move '>+1<CR>gv|
inoremap <silent> <C-S-k> <C-o>:move .-2<CR>|
inoremap <silent> <C-S-j> <C-o>:move .+1<CR>|


" Turbo navigation mode
" Modified to work with counts, see :help complex-repeat
nnoremap <silent> <S-j> @='10j'<CR>|xnoremap <silent> J @='10j'<CR>|
nnoremap <silent> <S-k> @='10k'<CR>|xnoremap <silent> K @='10k'<CR>|

" Get back some way of joining lines
nmap <silent> <S-f> $:s/\n\s*//<CR>:noh<CR>

" Map C-g to escape, b/c it's close and it's like emacs
nnoremap <silent> <C-g> <Esc>:nohlsearch<bar>pclose<CR>|
vnoremap <C-g> <Esc><Nul>| " <Nul> added to fix select mode problem
inoremap <C-g> <Esc>| inoremap kj <Esc>|
cnoremap <C-g> <C-c>
"tnoremap <C-g> <c-\><c-n>

" Macros (replay the macro recorded by qq)
nnoremap Q @q|

"comment entire file
nmap <F3> gg=G
nmap \p [p

"re-source this file
nmap ,s :source $HOME/.nvimrc<CR>

"view this file
nmap ,v :e! $HOME/.nvimrc<CR>
nmap ,b :e! $HOME/.bashrc<CR>
nmap <S-C-t> :tabnew<CR>:bn<CR>
nmap <S-C-q> :tabclose<CR>
nmap + :cn<CR>

"use shift j/k to nav in vis mode
nmap <s-down> j
nmap <s-up> k
vmap <s-down> j
vmap <s-up> k

"I didn't like the way vimshell worked, it geeked out on occasion
nmap <c-S>s :new \| vimshell bash<CR>

nmap <silent> <C-e> :TlistToggle<CR>
"nmap <C-l> :ls<CR>:b
map <C-l> \be
"shift to select
map <C-f> :Vexplore<CR>

imap <S-Down> <C-O>v
imap <S-Up> <C-O>v
imap <S-Right> <C-O>v
imap <S-Left> <C-O>v

map <F8>  <C-E>:sleep 500m<CR><C-E>:redraw<CR><F8>

nmap zz :set foldmethod=indent<CR>

set wildignore=*.o,*.obj,*.bak,*.exe

" for quick compiling
"set makeprg=make
"nmap <C-c> :make! -s <CR>:cc!<CR>

" gdb - stop & restart program from beginning
nmap <F5>  <C-Z>:sleep<CR>R:sleep<CR><F21>y

" info threads
"nmap <silent> <S-T> <F21>t

" bt
"nmap <silent> <S-S> <F21>s

set errorformat=%f:%l:\%m "GCC's error format
"set errorformat=%f:%l:\ %m,In\ file\ included\ from\ %f:%l:,\^I\^Ifrom\ %f:%l%m 
"advanced gcc

hi WhitespaceEOL ctermfg=red guifg=red
match WhitespaceEOL /\s\+$/

hi BeginTabs ctermfg=blue guifg=blue
match BeginTabs /^[\t ]*\t/

"show tabs, trailing whitespace, lines going off end of term
"if (!has("windows"))
" if (&termencoding == "utf-8") || has("gui_running")
"    if v:version >= 700
"       set list listchars=tab:Â»Â·,trail:Â·,extends:â¦,nbsp:_
"    else
"       set list listchars=tab:Â»Â·,trail:Â·,extends:<e2><80><a6>
"    endif
" else
"    if v:version >= 700
"       set list listchars=tab:>-,trail:.,extends:>,nbsp:_
"    else
"       set list listchars=tab:>-,trail:.,extends:>
"  endif
" endif
"endif
set list listchars=tab:>-,trail:.,extends:>,nbsp:_

" Nice statusbar
set laststatus=2
set statusline=
set statusline+=%-3.3n\                      " buffer number
set statusline+=%f\                          " file name
"set statusline+=%h%m%r%w                     " flags
set statusline+=\(%{strlen(&ft)?&ft:'none'}) " filetype
"set statusline+=%{&encoding},                " encoding
"set statusline+=%{&fileformat}]              " file format
set statusline+=%=                           " right align
"set statusline+=0x%-8B\                      " current char
set statusline+=%-14.(%l,%c%V%)\ %<%P        " offset

set noerrorbells                             " forget the audible errors


if v:version >= 700
inoremap <silent><Esc>      <C-r>=pumvisible()?"\<lt>C-e>":"\<lt>Esc>"<CR>
inoremap <silent><CR>       <C-r>=pumvisible()?"\<lt>C-y>":"\<lt>CR>"<CR>
inoremap <silent><Down>     <C-r>=pumvisible()?"\<lt>C-n>":"\<lt>Down>"<CR>
inoremap <silent><Up>       <C-r>=pumvisible()?"\<lt>C-p>":"\<lt>Up>"<CR>
inoremap <silent><PageDown> <C-r>=pumvisible()?"\<lt>PageDown>\<lt>C-p>\<lt>C-n>":"\<lt>PageDown>"<CR>
inoremap <silent><PageUp>   <C-r>=pumvisible()?"\<lt>PageUp>\<lt>C-p>\<lt>C-n>":"\<lt>PageUp>"<CR> 
endif



" Paragraph-ify the file
nmap L ggVGgq

" Use embedded python to add on a scientific calculater
" :command! -nargs=+ Calc :py print <args>
" :py from math import *

vmap <silent> gcc :TCommentRight<CR>

" remove trailing whitespace in clj, cljs files
autocmd BufWritePre *.clj :call RemoveTrailingWhitespace()
autocmd BufWritePre *.cljs :call RemoveTrailingWhitespace()

" remove trailing whitespace in python files
autocmd BufWritePre *.py :call RemoveTrailingWhitespace()
fun! RemoveTrailingWhitespace()
    let oldLine=line('.')
    execute ':%s/\s\+$//e'
    execute ':' . oldLine
endfun

" indent with < and >, works on regions too
nnoremap < <<
nnoremap > >>
vnoremap < <ESC>'<V'><gv
vnoremap > <ESC>'<V'>>gv

colorscheme cg3

let &titlestring = "v:" . expand("%:t")

if &term == "screen" || &term == "screen-256color"
    set t_ts=k
    set t_fs=\
endif

if &term == "screen" || &term == "screen-256color" || &term == "xterm"
    set title
endif

command! -nargs=0 SetWindowTitle
    \ | execute ':silent !'.'echo -ne "\033]0;v: ' . expand("%:t") . '\007"'
    \ | execute ':redraw!'

"auto BufEnter * :set title | let &titlestring = 'v:' . expand('%:t')
"auto BufEnter * :SetWindowTitle
auto VimLeave * :set t_ts=kbash\

au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces


let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='dark'

let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#whitespace#enabled = 0

function! AirLineCG3()
  call airline#parts#define_raw('filename', '%<%f %{&modified ? "+":""}')

  let g:airline_section_b = airline#section#create_left(['filename'])
  let g:airline_section_gutter = airline#section#create(['%='])
  let g:airline_section_c = airline#section#create([''])

  let g:airline_section_x = airline#section#create_right(['(%{strlen(&ft)?&ft:"none"})'])
  let g:airline_section_y = airline#section#create_right(['%l:%c'])
  let g:airline_section_z = airline#section#create_right(['%P'])
endfunction

autocmd Vimenter * call AirLineCG3()

let g:airline_mode_map = {
  \ 'n'  : 'N',
  \ 'i'  : 'I',
  \ 'R'  : 'R',
  \ 'v'  : 'V',
  \ 'V'  : 'V-L',
  \ 'c'  : 'C',
  \ 's'  : 'S',
  \ 'S'  : 'S-L',
  \ }

"autocmd TermOpen * set bufhidden=hide


" Removed title_only formatter - use default instead
" let g:airline#extensions#tabline#formatter = 'title_only'

