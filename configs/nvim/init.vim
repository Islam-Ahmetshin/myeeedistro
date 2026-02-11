set nocompatible
filetype plugin indent on
syntax enable

" --- Basic settings ---
set number relativenumber      " line numbers (absolute + relative)
set tabstop=4 shiftwidth=4 expandtab
set autoindent smartindent
set mouse=a                    " enable mouse
set clipboard=unnamedplus      " system clipboard
set termguicolors              " true colors
set cursorline                 " highlight current line
set scrolloff=5               " keep 5 lines above/below cursor
set lazyredraw                " don't redraw while executing macros
set updatetime=300           " faster update time (for LSP)
set hidden                   " allow switching buffers without saving
set noswapfile              " no .swp files
set undofile                " persistent undo
set undodir=/tmp/nvim-undo  " store undo files in RAM (fast!)
set undolevels=1000
set completeopt=menuone,noinsert,noselect  " completion menu
set shortmess+=c            " disable completion messages

" --- Built‑in auto‑pairing (no plugin) ---
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>
inoremap ' ''<Left>
inoremap " ""<Left>
inoremap ` ``<Left>

" --- Plugins (only essential) ---
call plug#begin('~/.local/share/nvim/plugged')

" Colorscheme (lightweight, pure Vim)
Plug 'sainnhe/gruvbox-material'

" LSP client (error checking, goto definition, hover)
Plug 'neovim/nvim-lspconfig'

" Autocompletion (lightweight, no snippets)
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'   " LSP source for nvim-cmp
Plug 'hrsh7th/cmp-buffer'     " buffer words completion
Plug 'hrsh7th/cmp-path'       " file path completion

" Fast file searching (triggered manually)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()

" --- Colorscheme: gruvbox-material ---
set background=dark
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_enable_bold = 1
let g:gruvbox_material_enable_italic = 1
let g:gruvbox_material_transparent_background = 0
colorscheme gruvbox-material

" --- LSP configuration (Python & C) ---
lua << EOF
-- Disable logging (saves disk I/O)
vim.lsp.set_log_level("off")

-- Disable virtual text diagnostics (cleaner, faster)
vim.diagnostic.config({ virtual_text = false, underline = true, signs = true })

local lspconfig = require('lspconfig')

-- Python (pylsp)
lspconfig.pylsp.setup{
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = { enabled = false },
        mccabe = { enabled = false },
        pyflakes = { enabled = true },   -- basic error checking
        jedi_completion = { enabled = true },
      }
    }
  }
}

-- C/C++ (clangd)
lspconfig.clangd.setup{}
EOF

" --- Autocompletion (nvim-cmp) ---
lua << EOF
local cmp = require'cmp'
cmp.setup {
  -- No snippet engine – keep it simple
  mapping = {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = 'nvim_lsp' },   -- from LSP
    { name = 'buffer' },     -- words in current buffer
    { name = 'path' },       -- file paths
  },
}
EOF

" --- Fast file search with fzf ---
nnoremap <C-p> :Files<CR>           " search files by name
nnoremap <leader>f :Rg<CR>          " search text inside files (needs ripgrep)

" --- Basic key mappings ---
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :wq<CR>
nnoremap <leader>s :source $MYVIMRC<CR>  " reload config

" --- Quick run for Python/C files ---
autocmd FileType python nnoremap <buffer> <F5> :w<CR>:!python3 %<CR>
autocmd FileType c nnoremap <buffer> <F5> :w<CR>:!gcc -o %:r % && ./%:r<CR>

" --- Useful hints for beginners ---
" :PlugInstall      – install all plugins (run once after editing)
" :LspInfo          – check which LSP servers are running
" K                 – hover documentation
" gd                – go to definition
" <C-p>             – fuzzy find files
" <leader>f         – fuzzy find text (requires ripgrep)