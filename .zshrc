export ZSH=/home/mao/.oh-my-zsh ZSH_DISABLE_COMPFIX=true

ZSH_THEME="wedisagree"

plugins=(git colored-man-pages tmux safe-paste docker docker-compose golang npm)
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
export PATH=$PATH:/usr/bin/core_perl/:~/npm-g/bin/:~/.cargo/bin

HISTSIZE=999999999
SAVEHIST=$HISTSIZE

alias recitediff="git diff --color-words --minimal -U100"
alias ctags="ctags --exclude=ctags --exclude=tags -L <(git ls-files -co --exclude-standard) ctags"
if hash exa; then
  alias ls=exa
fi
alias newcontainer="docker run -it --entrypoint bash -v \$(pwd):/tmp/workspace -v \$(pwd)/.git:/tmp/workspace/.git:ro -v \$(pwd)/.vscode:/tmp/workspace/.vscode:ro -w /tmp/workspace -u \$(id -u):\$(id -g) --rm --network=ss_ss -e HTTP_PROXY=http://polipo:8080 -e HTTPS_PROXY=http://polipo:8080"
alias diff="diff -u --color=always"
alias httpserverhere="(sleep 1; xdg-open http://localhost:8000) & newcontainer -p 127.0.0.1:8000:8000 python -c 'python -m http.server'"
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
