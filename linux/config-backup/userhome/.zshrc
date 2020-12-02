# Path to your oh-my-zsh installation.
[[ -d /usr/share/oh-my-zsh ]] && export ZSH=/usr/share/oh-my-zsh
[[ -d $HOME/.oh-my-zsh ]] && export ZSH=$HOME/.oh-my-zsh

# Theme  name: value is 'random' or figure a theme name
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
ZSH_THEME="robbyrussell" #ys
#ZSH_THEME='random' #enable ZSH_THEME_RANDOM_CANDIDATES, must uncomment this line
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=99

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
#ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time stamp shown in the history command output.
# You can set one of the optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications, see 'man strftime' for details.
HIST_STAMPS="mm/dd/yyyy"


# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# load plugins.They can be found in ~/.oh-my-zsh/plugins/*
# more plugins, more launch time
plugins=(git autojump zsh-autosuggestions)

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nano'
fi

ZSH_CACHE_DIR=$HOME/.oh-my-zsh-cache
[[ -d $ZSH_CACHE_DIR ]] || mkdir $ZSH_CACHE_DIR

source $ZSH/oh-my-zsh.sh

autoload -U compinit
compinit

###++++++++++++++++++++++++++
unalias -a
os=$(uname)

if [[ $os == Linux ]]; then #iproute
  innerip=$(ip addr | grep -o -P '1[^2]?[0-9]?(\.[0-9]{1,3}){3}(?=\/)')
  gateway=$(ip route | grep 'via' | cut -d ' ' -f 3 | uniq)
elif [[ $os == Darwin ]]; then #net-tools (ifconfig)
  export HOSTNAME=$HOST
  innerip=$(ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | cut -d " " -f 2)
  gateway=$(route get default | grep gateway | grep -oE '[0-9.]+')
fi

echo -e "+++ $(uname -rsnm) +++
\e[1;36m$(date)\e[0m
\e[1;32m$gateway\e[0m <-- \e[1;31m$innerip\e[0m"

# ******** important! files backup******
configs_files=(.ssh/config .condarc .zshrc .gitignore_global .gitconfig .vimrc) #.bashrc  .makepkg.conf # .bash-powerline.sh)
path_for_bakcup=~/Documents/it/itnotes/linux/config-backup/userhome

function backupconfigs() {
  cd $HOME
  for config in ${configs_files[*]}; do
    [[ -f $config ]] || continue

    if [[ $config == .ssh/config ]]; then
      cp -av $config ~/Documents/network/ssh/
    else
      cp -av ~/$config $path_for_bakcup/
    fi
  done
}

function restoreconfigs() {
  for config in ${configs_files[*]}; do
    if [[ $config == .ssh/config ]]; then
      cp -av ~/Documents/network/ssh/config ~/.ssh/config
    else
      cp -av $path_for_bakcup/$config ~/
    fi
  done
}


#===system commands===

#---package manager---
if [[ $os == Linux ]]; then
  if [[ $(which pacman 2>/dev/null) ]]; then
    alias pacman='sudo pacman'
    alias orphan='sudo pacman -Rscn $(pacman -Qtdq)'
    alias pkgclean='sudo paccache -rk 2 2>/dev/null'
    #upgrade need yay
    alias upgrade='yay && pkgclean -rk 2 && orphan'
    #makepkg aur
    alias aurinfo='makepkg --printsrcinfo > .SRCINFO ; git status'

  elif [[ $(which apt 2>/dev/null) ]]; then
    alias apt='sudo apt'
    alias orphan='sudo apt purge $(deborphan)'
    alias upgrade='sudo apt dist-upgrade'
    alias pkgclean='sudo apt autoremove && sudo apt autoclean'
  fi
elif [[ $os == Darwin ]]; then
  function brew_install_config() {
    brewinstall='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" && '
    #使用ustc源
    cd "$(brew --repo)"
    git remote set-url origin https://mirrors.ustc.edu.cn/brew.git
    # brew core git
    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
    git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
    # brew cask git
    cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
    git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
    #
    cd && brew tap beeftornado/rmtree
    echo "use 'brew rmtree'  instead of 'brew uninstall' "
    echo "rmtree will remove package and dependcies (only for formulas)."
  }

  #export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
  export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
#  export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles

  alias update='brew update && echo ---outdated---  && brew outdated'
  alias upgrade='brew upgrade --cask && brew upgrade'
  alias pkgclean='brew cleanup'
  alias finderplugin='brew cask install qlcolorcode qlstephen qlmarkdown quicklook-json qlimagesize quicklookase qlvideo webpquicklook'
  #suspicious-package suspicious-package quicklook-pat provisionql
fi

#system commands alias
if [[ $os == Linux ]]; then
  alias trim='sudo fstrim -v /home && sudo fstrim -v /'
  # clear 2 weeks ago logs
  alias logclean='sudo journalctl --vacuum-time=1weeks'
elif [[ $os == Darwin ]]; then
  #sudo gem install iStats
  alias tmquickly='sudo sysctl debug.lowpri_throttle_enabled=0'
  alias tmlistsnap='tmutil listlocalsnapshotdates'
  alias tmlistbackups='tmutil listbackups'
  alias tmrmsnap=' tmutil deletelocalsnapshots '
  alias tmrmbackup='sudo tmutil delete '
fi

#---temporary locale---
#lang
alias sc='export LANG=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8'
alias tc='export LANG=zh_TW.UTF-8 LC_CTYPE=zh_TW.UTF-8 LC_MESSAGES=zh_TW.UTF-8'
alias en='export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8'

#user login info
alias lastb='sudo lastb | tac'
alias lastlog='lastlog|grep -Ev  "\*{2}.+\*{2}"'

#---file operation---
alias ll='ls -lh'
alias la='ls -lah'

if [[ -d $HOME/.local/share/Trash/files ]]
then
  alias rm='mv -f --target-directory=$HOME/.local/share/Trash/files/'
fi

alias cp='cp -i'

alias grep='grep --color'

alias tree='tree -C -L 1 --dirsfirst'

#---network---
alias ping='ping -c 4'
# proxychains
PROXYCHAINS_SOCKS5=1086
[[ $os == Linux ]] &&  PROXYCHAINS_SOCKS5=1080
alias px='proxychains4'

# ssh server
alias sshstart='sudo systemctl start sshd'
# mosh
alias mosh="en && mosh "

#iconv -- file content encoding
alias iconvgbk='iconv -f GBK -t UTF-8'
#convmv -- filename encoding
alias convmvgbk='convmv -f GBK -T UTF-8 --notest --nosmart'

#docker
alias dockerstart='sudo systemctl start docker && docker ps -a'

#libvirtd
alias virtstart='sudo modprobe virtio && sudo systemctl start libvirtd ebtables dnsmasq'

# nmap
#scan alive hosts
alias 'nmap-ports'="sudo nmap -sS $(echo $gateway | cut -d '.' -f 1-3).0/24"
alias 'nmap-hosts'="nmap -sP $(echo $gateway | cut -d '.' -f 1-3).0/24"
alias 'nmap-os'="sudo nmap -O $(echo $gateway | cut -d '.' -f 1-3).0/24"


#---vim plugin
#pacman -S vim-plugin --no-comfirm
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

#安装中文古诗词
function install_fortune_gushici() {
  git clone git@github.com:ruanyf/fortunes.git
  if [[ $os = Darwin ]]
  then
    which fortune || brew install fortune
    cp -av fortunes/data/* /usr/local/Cellar/fortune/9708/share/games/fortunes
  elif [[ $(which pacman) ]]
  then
    sudo pacman -S fortunes --noconfirm
    sudo cp -av fortunes/data/* /usr/share/fortunes/
  fi
}

fortune -e tang300 song100 2>/dev/null #先秦 两汉 魏晋 南北朝 隋代 唐代 五代 宋代 #金朝 元代 明代 清代

#-----DEV-----
#-npm
#npm -g list --depth=0
alias npmlistg='npm -g list --depth=0'
alias npmtaobao='npm config set registry https://registry.npm.taobao.org'

#-python
alias python=python3
alias pip=pip3
alias pipoutdated='pip list --outdated'
alias pipupgrade='pip install --upgrade $(echo $(pip list --outdate|sed -n "3,$ p"|cut -d " " -f 1))'

#-R
if [[ $os == Darwin && -f /usr/local/bin/R ]]; then
#R use openblas but mac provides BLAS
#export LDFLAGS="-L/usr/local/opt/openblas/lib"
#export CPPFLAGS="-I/usr/local/opt/openblas/include"
fi

#-Golang |only gopaht need set. default gopath is ~/go
export  GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
gopath=/Users/levin/Library/golang
[[ -d $gopath ]] && export GOPATH=$gopath

#---macos PATH
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/local/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/usr/local/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

alias condaclean='conda clean -ady'

#-anaconda/miniconda
#prevent auto active conda env, execute:
#conda config --set auto_activate_base false

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
