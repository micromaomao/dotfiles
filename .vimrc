set nocompatible              " be iMproved, required
set hidden
set showtabline=0
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" Tree
Plugin 'scrooloose/nerdtree'

Plugin 'bling/vim-airline'
let g:airline_powerline_fonts = 1

Plugin 'vim-airline/vim-airline-themes'
let g:airline_theme='papercolor'

" Real time git diff
Plugin 'airblade/vim-gitgutter'

Plugin 'altercation/vim-colors-solarized'

" Relative line numbers
Plugin 'myusuf3/numbers.vim'

Plugin 'digitaltoad/vim-pug'

" :ExecuteBuffer
" :ExecuteSelction
Plugin 'JarrodCTaylor/vim-shell-executor'

Plugin 'terryma/vim-multiple-cursors'

" ES6
Plugin 'othree/yajs.vim'

Plugin 'mxw/vim-jsx'

Plugin 'valloric/YouCompleteMe'

Plugin 'nathanaelkane/vim-indent-guides'
let g:indent_guides_enable_on_vim_startup = 1

Plugin 'tpope/vim-surround'

" Delete and insert stuff in pairs
" Plugin 'jiangmiao/auto-pairs'
" let g:AutoPairsShortcutBackInsert = '<C-l>'
Plugin 'Raimondi/delimitMate'

" Fuzzy search
Plugin 'ctrlpvim/ctrlp.vim'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']

" Commit reminder
Plugin 'esneider/YUNOcommit.vim'
let g:YUNOcommit_after = 30

" Fast moving cursor
Plugin 'easymotion/vim-easymotion'

map <Leader> <Plug>(easymotion-prefix)
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

" All of your Plugins must be added before the following line
call vundle#end()            " required
" filetype plugin on           " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

map ,n :NERDTreeToggle<CR>
" Auto open NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

let g:airline#extensions#tabline#enabled = 1
syntax enable

set number

set expandtab

set tags+=.git/tags

set nowrap
setlocal spell spelllang=en_us

set cursorline
set cursorcolumn

colorscheme solarized
set background=light

set autoindent
set tabstop=2
set shiftwidth=2
set softtabstop=2
setlocal expandtab sw=2 sts=2 et

function! WrapForTmux(s)
  if !exists('$TMUX')
    return a:s
  endif

  let tmux_start = "\<Esc>Ptmux;"
  let tmux_end = "\<Esc>\\"

  return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
endfunction

let &t_SI .= WrapForTmux("\<Esc>[?2004h")
let &t_EI .= WrapForTmux("\<Esc>[?2004l")

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

:set laststatus=2

match ErrorMsg '\s\+$'

vnoremap // y/<C-R>"<CR>
