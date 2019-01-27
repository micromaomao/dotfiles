export ZSH=/home/mao/.oh-my-zsh ZSH_DISABLE_COMPFIX=true

ZSH_THEME="wedisagree"

plugins=(git colored-man-pages tmux safe-paste docker docker-compose golang npm vi-mode)
source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

export EDITOR='vim'
if [[ -z $SSH_CONNECTION ]]; then
  export HTTPS_PROXY=http://127.3.0.4:8080 HTTP_PROXY=http://127.3.0.4:8080
  export ALL_PROXY="socks5://127.3.0.4:1080"
  export https_proxy=$HTTPS_PROXY http_proxy=$HTTP_PROXY all_proxy=$ALL_PROXY
  alias noproxy="HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= http_proxy= https_proxy= all_proxy="
  alias mwssh="ssh mao@127.23.0.234 -p 22233"
fi
export GOPATH=/home/mao/go
export PATH=$PATH:/usr/bin/core_perl/:~/npm-g/bin/

HISTSIZE=999999999
SAVEHIST=$HISTSIZE

alias recitediff="git diff --color-words --minimal -U100"
alias ctags="ctags --exclude=ctags --exclude=tags -L <(git ls-files -co --exclude-standard) ctags"
alias ls=exa
# Don't let others see our files.
umask o=


# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:|?=** m:{a-z\-}={A-Z\_}'

