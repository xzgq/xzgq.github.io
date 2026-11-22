#!/usr/bin/env bash

mkdir -p ~/.config/vim/{autoload,plugged}
vim_plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
vim_plug_file='~/.config/vim/autoload/plug.vim'
curl -sfLo "$vim_plug_file" --create-dirs "$vim_plug_url" || (
    echo '下载 junegunn/vim-plug 失败'
    exit
)
pushd ~/.config/vim/plugged > /dev/null
while read pack ; do
    git clone git@github.com:$pack.git
done << EOF
jiangmiao/auto-pairs
preservim/nerdtree
vim-airline/vim-airline
majutsushi/tagbar
dense-analysis/ale
preservim/nerdcommenter
cespare/vim-toml
benstaniford/vim-json-format
imsnif/vim-jsonc
neoclide/coc-json
tpope/vim-fugitive
airblade/vim-gitgutter
EOF
popd > /dev/null

[ -f ~/.vimrc ] && mv ~/.vimrc ~/.config/vim/vimrc
cat >> ~/.config/vim/vimrc << EOF
" ===== 基础配置 =====
set nocompatible          " 禁用 vi 兼容模式，启用 Vim 特有功能 
syntax on                 " 开启语法高亮，对代码阅读至关重要 
filetype plugin indent on " 开启文件类型检测，并自动加载对应缩进和插件 

" ===== 界面与显示 =====
set number                " 显示行号 
set relativenumber        " 显示相对行号，方便用 hjkl 快速移动 
set ruler                 " 在右下角显示光标位置 
set showcmd               " 在右下角显示未完成的命令 
set wildmenu              " 在底部增强命令补全，有可视化菜单 
set showmatch             " 高亮匹配的括号 [{()}] 
set laststatus=2          " 始终显示状态栏 

" ===== 搜索设置 =====
set incsearch             " 边输入边搜索，实时高亮 
set hlsearch              " 高亮所有搜索结果 
set ignorecase            " 搜索时忽略大小写 
set smartcase             " 如果搜索包含大写字母，则自动变为大小写敏感 

" 缩进与格式（统一用4个空格）
set expandtab             " 将 Tab 键转换为空格 
set tabstop=4             " 设置 Tab 键显示为 4 个空格的宽度 
set softtabstop=4         " 设置按 Tab 键或退格键时，移动 4 个空格 
set shiftwidth=4          " 设置自动缩进的宽度为 4 个空格 
set autoindent            " 开启自动缩进 
set smartindent           " 开启智能缩进，对类C语言很友好 

" 便捷操作（可选）
" 用 jk 或 jj 退出插入模式，比按 Esc 更高效 
inoremap jk <Esc>
" 用 ; 代替 : ，减少按键次数 
nnoremap ; :

" 将插件安装到 ~/.config/vim/plugged 目录
call plug#begin('~/.config/vim/plugged')

" 选择安装的插件
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'jiangmiao/auto-pairs'

call plug#end()

" ===== NERDTree 配置 =====
" 按 F2 键打开/关闭文件浏览器
nnoremap <F2> :NERDTreeToggle<CR>
" 当 NERDTree 是最后一个窗口时自动关闭 Vim
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" ===== vim-airline 配置 =====
" 始终显示状态栏
set laststatus=2
" 启用更美观的字体（如果安装了 Powerline 字体）
let g:airline_powerline_fonts = 1
" 显示 Buffer 列表
let g:airline#extensions#tabline#enabled = 1

" ===== auto-pairs 配置（无需配置，开箱即用） =====
" 它会自动帮你补全 (), [], {}, '', ""

EOF

[ -d ~/.vim  ] && mv ~/.vim ~/.config/vim.old

