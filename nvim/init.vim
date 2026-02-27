
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
"%s/\\n\\s*\\(word\\)/\\1/gc - replace /nspaces word with just word
"
"set nowritebackup


set mouse-=a
set clipboard=unnamedplus

set backupdir=/tmp
set ss=1                        " Nice sidescroll set siso=9                      " Even nicer sidescroll ;)
set nowrap                      " dont wrap lines
set sm                          " show matching paren
set ww=<,>,[,],h,l,b,s,~        " normal cursor movement
set guioptions-=T               " no toolbar 
set background=dark
set novisualbell


colorscheme cg3
syntax on
syntax enable                      " enable syntax highlighting
"let $NVIM_TUI_ENABLE_TRUE_COLOR=1
hi normal   ctermfg=white  ctermbg=black guifg=white  guibg=black
hi nontext  ctermfg=blue   ctermbg=black guifg=blue   guibg=black

filetype on                     " understand the file type
filetype plugin indent on

set tabstop=4                   " 4 spaces for tabs
set softtabstop=4               " tab causes indent
set shiftwidth=4                " 4 spaces
set expandtab                   " spaces instead of tabs

" Ctrl-P with capital p, ctrl-p is previous buffer
set nocp
execute pathogen#infect()
let g:ctrlp_map = '<S-C-O>'

let g:ale_lint_on_text_changed = 'never'

"autocmd BufEnter * lcd %:p:h   " change to directory of current file automatically (put in _vimrc)

" universal-ctags: macOS keg-only path, then Linux /usr/bin/ctags
if executable('/opt/homebrew/opt/universal-ctags/bin/ctags')
  let Tlist_Ctags_Cmd = '/opt/homebrew/opt/universal-ctags/bin/ctags'
elseif executable('/usr/local/opt/universal-ctags/bin/ctags')
  let Tlist_Ctags_Cmd = '/usr/local/opt/universal-ctags/bin/ctags'
elseif executable('/usr/bin/ctags')
  let Tlist_Ctags_Cmd = '/usr/bin/ctags'
endif
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

"set cinkeys=0{,0},:,0#,!<Tab>,<Return>,!^F

autocmd FileType python,c,cpp,h,hpp,slang set cindent expandtab
autocmd FileType make,css,eruby,html set noexpandtab shiftwidth=4
autocmd FileType javascript,html set expandtab shiftwidth=2
autocmd FileType plaintex set wrap!
autocmd BufNewFile,BufRead *.joke set filetype=clojure
" Don't highlight underscores as errors in markdown
autocmd FileType markdown syn clear markdownError
autocmd FileType markdown hi link markdownError NONE
autocmd FileType markdown hi markdownError guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE
autocmd FileType markdown setlocal conceallevel=2 wrap linebreak signcolumn=no
" Enable folding for markdown based on headings
autocmd FileType markdown setlocal foldmethod=expr
autocmd FileType markdown setlocal foldexpr=MarkdownFoldLevel(v:lnum)
autocmd FileType markdown setlocal foldtext=getline(v:foldstart)
autocmd FileType markdown setlocal foldlevel=99
autocmd BufRead *.md normal zR

" Function to determine fold level based on markdown headings
if !exists('*MarkdownFoldLevel')
    function! MarkdownFoldLevel(lnum)
        let line = getline(a:lnum)
        " Check for ATX-style headings (# Heading)
        if line =~ '^#\+\s'
            return '>' . len(matchstr(line, '^#\+'))
        endif
        return '='
    endfunction
endif

autocmd FileType go set list listchars=tab:\ \ ,trail:.,extends:>,nbsp:_

" Configure ALE for Python files
autocmd FileType python let b:ale_linters = ['pyright', 'ruff']
autocmd FileType python let b:ale_fixers = ['ruff']
let g:ale_python_pyright_auto_uv = 1

" LSP keybindings
nmap gd :ALEGoToDefinition<CR>
nmap gr :ALEFindReferences<CR>
nmap gh :ALEHover<CR>

set previewheight=12               " set gdb console initial height


set viminfo=/10,'10,r/mnt/zip,r/mnt/floppy,f0,h,\\"100

set wildmode=list:longest,full

set showmode
set showcmd

set hlsearch
set incsearch
set ignorecase
set smartcase


"Switch Buffers with c-n and c-p
map <C-n> :bn!<CR>
""map <C-p> :bp!<CR>

map <C-p> :CtrlP<CR>
""map <C-p> :bp!<CR>

" (GUI) Live line reordering (very useful)
nnoremap <silent> <C-S-k> :move .-2<CR>|
nnoremap <silent> <C-S-j> :move .+1<CR>|
vnoremap <silent> <C-K> :move '<-2<CR>gv|
vnoremap <silent> <C-J> :move '>+1<CR>gv|

nnoremap <silent> <C-k> :move .-2<CR>|
nnoremap <silent> <C-j> :move .+1<CR>|

" Bring back digraphs in insert mode
"inoremap <silent> <C-S-k> <C-o>:move .-2<CR>|
"inoremap <silent> <C-S-j> <C-o>:move .+1<CR>|


" Turbo navigation mode
" Modified to work with counts, see :help complex-repeat
nnoremap <silent> <S-j> @='10j'<CR>|xnoremap <silent> J @='10j'<CR>|
nnoremap <silent> <S-k> @='10k'<CR>|xnoremap <silent> K @='10k'<CR>|

" Get back some way of joining lines
nmap <silent> <S-f> :s/\n\s*//<CR>:noh<CR>

" Ctrl+V+V to paste from system clipboard (normal: after cursor, insert: inline, terminal: feeds to shell)
" Single Ctrl+V is left free for visual block selection
nnoremap <C-v><C-v> "+p
inoremap <C-v><C-v> <C-r>+
tnoremap <C-v><C-v> <C-\><C-n>"+pi

" Map C-g to escape, b/c it's close and it's like emacs
nnoremap <silent> <C-g> <Esc>:nohlsearch<bar>pclose<CR>|
vnoremap <C-g> <Esc><Nul>| " <Nul> added to fix select mode problem
inoremap <C-g> <Esc>| inoremap kj <Esc>|
cnoremap <C-g> <C-c>

" Exit terminal mode with ctrl+g
tnoremap <C-g> <C-\><C-n>

" Navigate windows using usual keys in terminal mode
tnoremap <C-w>w <C-\><C-n><C-w>w
tnoremap <C-w>h <C-\><C-n><C-w>h
tnoremap <C-w>j <C-\><C-n><C-w>j
tnoremap <C-w>k <C-\><C-n><C-w>k
tnoremap <C-w>l <C-\><C-n><C-w>l

" In a terminal buffer's normal mode, send Up/Down/Enter to the terminal instead of moving cursor
" C-e is a no-op in normal mode (don't trigger TlistToggle), but passes through in terminal mode
function! s:TermNormalMappings()
  nnoremap <buffer> <Up>   i<Up><C-\><C-n>
  nnoremap <buffer> <Down> i<Down><C-\><C-n>
  nnoremap <buffer> <CR>   i<CR><C-\><C-n>
  nnoremap <buffer> <C-e>  <Nop>
endfunction
autocmd TermOpen * call s:TermNormalMappings()
command! TermNormalMappings call s:TermNormalMappings()

" Macros (replay the macro recorded by qq)
nnoremap Q @q|

"comment entire file
nmap <F3> gg=G
nmap \\p [p
 
command! Keymap :e $HOME/.config/nvim/doc/keymap.md
nmap gm :Keymap<CR>
nmap tt :rightbelow vsplit \| terminal<CR>:startinsert<CR>

"re-source this file
" Only define function if it doesn't exist (so it persists across reloads)
if !exists('*ReloadConfig')
    function! ReloadConfig()
        " Close nvim-tree if it's open
        silent! NvimTreeClose
        " Source the config
        source $HOME/.config/nvim/init.vim
        " Refresh airline
        AirlineRefresh
        call AirLineCG3()
        " Re-enable rainbow parentheses
        RainbowParenthesesActivate
        RainbowParenthesesLoadRound
        RainbowParenthesesLoadSquare
        RainbowParenthesesLoadBraces
        " Re-enable render-markdown for current buffer
        silent! lua require('render-markdown').enable()
        echo "init.vim reloaded!"
    endfunction
endif
nmap ,s :call ReloadConfig()<CR>
 
"view this file
nmap ,v :e! $HOME/.config/nvim/init.vim<CR>
nmap ,b :e! $HOME/.bashrc<CR>
nmap <S-C-t> :tabnew<CR>:bn<CR>
nmap <S-C-q> :tabclose<CR>
nmap + :cn<CR>

"use shift j/k to nav in vis mode
nnoremap <s-down> j
nnoremap <s-up> k
vnoremap <s-down> j
vnoremap <s-up> k

nmap <silent> <C-e> :TlistToggle<CR>
"nmap <C-l> :ls<CR>:b
map <C-l> \be
"shift to select


imap <S-Down> <C-O>v
imap <S-Up> <C-O>v
imap <S-Right> <C-O>v
imap <S-Left> <C-O>v

set wildignore=*.o,*.obj,*.bak,*.exe

hi WhitespaceEOL ctermfg=red guifg=red
match WhitespaceEOL /\\s\\+$/

hi BeginTabs ctermfg=blue guifg=blue
match BeginTabs /^[\\t ]*\\t/

set list listchars=tab:>-,trail:.,extends:>,nbsp:_

" " Nice statusbar
set laststatus=2
set statusline=
set statusline+=%-3.3n\\                      " buffer number
set statusline+=%f\\                          " file name
set statusline+=\\(%{strlen(&ft)?&ft:'none'}) " filetype
set statusline+=%=                           " right align

set noerrorbells                             " forget the audible errors

" Paragraph-ify the file
nmap L ggVGgq

" Update go imports on write
autocmd BufWritePre *.go :GoImports

" remove trailing whitespace in clj, cljs files
autocmd BufWritePre *.clj :call RemoveTrailingWhitespace()
autocmd BufWritePre *.yaml :call RemoveTrailingWhitespace()
autocmd BufWritePre *.yml :call RemoveTrailingWhitespace()
autocmd BufWritePre *.cljs :call RemoveTrailingWhitespace()
autocmd BufWritePre *.sh :call RemoveTrailingWhitespace()

" remove trailing whitespace in python files
autocmd BufWritePre *.py :call RemoveTrailingWhitespace()

" Remove trailing whitespace on save
function! RemoveTrailingWhitespace()
    if !exists('b:no_trailing_whitespace')
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
    endif
endfunction

" indent with < and >, works on regions too
nnoremap < <<
nnoremap > >>
vnoremap < <ESC>'<V'><gv
vnoremap > <ESC>'<V'>>gv



let &titlestring = "v:" . expand("%:t")

if &term == "screen" || &term == "screen-256color"
    set t_ts=k
    set t_fs=\\
endif

if &term == "screen" || &term == "screen-256color" || &term == "xterm"
    set title
endif

command! -nargs=0 SetWindowTitle
    \ | execute ':silent !'.'echo -ne "\\033]0;v: ' . expand("%:t") . '\\007"'
    \ | execute ':redraw!'

"auto BufEnter * :set title | let &titlestring = 'v:' . expand('%:t')
"auto BufEnter * :SetWindowTitle
auto VimLeave * :set t_ts=kbash\\

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

" easy way to comment / uncomment blocks
noremap ccc :TCommentRight<CR>

" Removed title_only formatter - use default instead
" let g:airline#extensions#tabline#formatter = 'title_only'

let g:EasyMotion_do_mapping = 0 " Disable default mappings

" Bi-directional find motion
" `s{char}{char}{label}`
nmap s <Plug>(easymotion-overwin-f2)

" Turn on case insensitive feature
let g:EasyMotion_smartcase = 1
let g:EasyMotion_startofline = 0

"set up taglist to work with clojure
let tlist_clojure_settings  = 'lisp;f:function'
let tlist_markdown_settings = 'markdown;s:section'

"The Leader
"let mapleader="\<Space>"

if has("nvim")
  tnoremap <Leader>e <C-\><C-n>
  tnoremap <C-Enter> startinsert
  au TermOpen * let g:last_term_job_id = b:terminal_job_id
endif

function! SendToTerm(lines)
  call jobsend(g:last_term_job_id, add(a:lines, ''))
endfunction

function! ResetReplTerm()
    " if lost which term is a repl term, call from a repl term
  let g:last_term_job_id = b:terminal_job_id
endfunction

function! SendToREPL(sexp)
  call fireplace#session_eval(a:sexp)
endfunction

function! SyncRepl()
  call SendToREPL("(require '[clojure.pprint :refer [pprint]])(require '[clojure.repl :refer :all])")
  call SendToTerm([" (in-ns '" . fireplace#ns() . ") "])
endfunction

function! RefreshNS()
  call SendToREPL("(require '[clojure.tools.namespace.repl :refer [refresh]])(refresh)")
endfunction

function! s:get_visual_selection()
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, " ")
endfunction

function! SendSelectionToTerm()
  let sel = s:get_visual_selection()
  call SendToTerm([sel])
  exe "norm! \<esc>"
endfunction

function! SendCurrentSexprToTerm()
  call PareditFindOpening('(',')',1)
  call SendSelectionToTerm()
endfunction


" C-R commands for repl interaction
nmap <silent> <C-s>e :call SendCurrentSexprToTerm()<CR>
nmap <silent> <C-s>y :call SyncRepl()<CR>
nmap <silent> <C-s>r :call ResetReplTerm()<CR>
vmap <silent> <C-s>s :call SendSelectionToTerm()<CR>
nmap <silent> <C-c>k :Require<CR>
nmap <silent> <C-c>j :Eval<CR>

"autoclose tags
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap " ""<Left>
inoremap [ []<Left>


"Tab to switch to next open buffer
nnoremap <Tab> :bnext<cr>
"Shift + Tab to switch to previous open buffer
nnoremap <S-Tab> :bprevious<cr>
"leader key twice to cycle between last two open buffers
nnoremap <leader><leader> <c-^>

" ===== nvim-tree configuration =====
" Disable netrw (recommended by nvim-tree)
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" Enable 24-bit color
set termguicolors

lua << EOF
-- Enable treesitter highlighting for markdown
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(ev)
    vim.treesitter.start(ev.buf, 'markdown')
  end,
})

-- Setup nvim-notify
local notify = require('notify')
notify.setup({ timeout = 3000, render = 'compact' })
vim.notify = notify

-- Setup nvim-web-devicons
require('nvim-web-devicons').setup()

-- Setup nvim-tree
require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
  },
  update_focused_file = {
    enable = true,
  },
  on_attach = function(bufnr)
    local api = require('nvim-tree.api')
    api.config.mappings.default_on_attach(bufnr)
    -- Override C-t inside tree to close instead of going to parent
    vim.keymap.set('n', '<C-t>', api.tree.close, { buffer = bufnr, noremap = true, silent = true })
  end,
})

-- Setup render-markdown
require('render-markdown').setup({
  enabled = true,
  render_modes = true,
  debounce = 30,
  anti_conceal = {
    enabled = true,
    disabled_modes = { 'n' },
  },
  win_options = {
    concealcursor = {
      rendered = 'n',
    },
  },
  indent = {
    enabled = true,
    skip_level = 1,
    skip_heading = true,
    icon = '',
    per_level = 4,
  },
  code = {
    border = 'thin',
    above = '─',
    below = '─',
    language_border = '─',
    width = 'block',
  },
})

local function set_markdown_highlights()
  local green  = vim.g.color_green
  local cyan   = vim.g.color_cyan
  local purple = vim.g.color_purple
  local peach  = vim.g.color_peach
  local blue   = vim.g.color_blue
  -- Heading icons: dim
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4Bg', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5Bg', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH6Bg', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1',   { fg = '#555555' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2',   { fg = '#555555' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3',   { fg = '#555555' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4',   { fg = '#555555' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5',   { fg = '#555555' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH6',   { fg = '#555555' })
  -- Heading text: green gradient (bright → muted)
  vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = green,     bold = true, underline = true })
  vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = green,     bold = true, underline = true })
  vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = '#02a456', bold = true })
  vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = '#028c48' })
  vim.api.nvim_set_hl(0, '@markup.heading.5.markdown', { fg = '#02743c' })
  vim.api.nvim_set_hl(0, '@markup.heading.6.markdown', { fg = '#015c30' })
  -- Bold: peach
  vim.api.nvim_set_hl(0, '@markup.strong',             { fg = peach, bold = true })
  vim.api.nvim_set_hl(0, '@text.strong',               { fg = peach, bold = true })
  -- Inline code: purple
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline',   { fg = purple, bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeBorder',   { fg = '#0d1a2a', bg = blue })
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInfo',     { fg = blue })
  vim.api.nvim_set_hl(0, '@markup.raw.block.markdown', { fg = blue })
  vim.api.nvim_set_hl(0, 'RenderMarkdownCode',         { bg = 'NONE' })
end

set_markdown_highlights()
vim.api.nvim_create_autocmd('VimEnter',    { callback = set_markdown_highlights })
vim.api.nvim_create_autocmd('ColorScheme', { callback = set_markdown_highlights })

-- notify_done: called via nvim --server RPC when a shell `notify` wrapper finishes.
-- Usage from shell: nvim --server "$NVIM" --remote-expr "v:lua.notify_done('cmd', code[, 'msg'])"
_G.notify_done = function(cmd, code, msg)
  vim.schedule(function()
    local icon  = code == 0 and '✓' or '✗'
    local level = code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
    local text  = icon .. ' ' .. cmd
    if msg and msg ~= '' then
      text = text .. '\n' .. msg
    end
    vim.notify(text, level)
  end)
  return ''
end
EOF

" nvim-tree keybindings
" ff - find current file in tree and expand all folders to show it
nnoremap ff :NvimTreeFindFile<CR>
" Toggle nvim-tree
nnoremap <C-t> :NvimTreeToggle<CR>
" Clean up stale nvim-tree buffers if you get buffer errors
command! NvimTreeCleanup :for buf in getbufinfo() | if buf.name =~ 'NvimTree_' | execute 'bwipeout! ' . buf.bufnr | endif | endfor
