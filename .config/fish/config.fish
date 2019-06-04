set -x EDITOR 'vim'
if [ -z $SSH_CONNECTION ]
  set -x HTTPS_PROXY http://127.3.0.4:8080
  set -x HTTP_PROXY http://127.3.0.4:8080
  set -x ALL_PROXY "socks5://127.3.0.4:1080"
  set -x https_proxy $HTTPS_PROXY
  set -x http_proxy $HTTP_PROXY
  set -x all_proxy $ALL_PROXY
  alias noproxy="env HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= http_proxy= https_proxy= all_proxy="
  alias mwssh="ssh mao@127.23.0.234 -p 22233"
end
set -x GOPATH /home/mao/go
set -x PATH $PATH:/usr/bin/core_perl/:~/npm-g/bin/:~/.cargo/bin
set PATH (echo "$PATH" | tr : \n | sort -u | head -c-1 | tr \n :) # Remove duplicates

abbr recitediff "git diff --color-words --minimal -U100"
alias ctags "ctags --exclude=ctags --exclude=tags -L <(git ls-files -co --exclude-standard) ctags"
alias ls exa
alias newcontainer "docker run -it --entrypoint bash -v (pwd):/tmp/workspace:ro -w /tmp/workspace -u (id -u):(id -g) --rm --network=ss_ss -e HTTP_PROXY=http://polipo:8080 -e HTTPS_PROXY=http://polipo:8080"
alias newcontainerrw "docker run -it --entrypoint bash -v (pwd):/tmp/workspace -v (pwd)/.git:/tmp/workspace/.git:ro -v (pwd)/.vscode:/tmp/workspace/.vscode:ro -w /tmp/workspace -u (id -u):(id -g) --rm --network=ss_ss -e HTTP_PROXY=http://polipo:8080 -e HTTPS_PROXY=http://polipo:8080"
alias diff "diff -u --color=always"
alias httpserverhere ": (sleep 1; xdg-open http://localhost:8000) & newcontainer -p 127.0.0.1:8000:8000 python -c \"python -m http.server\""
alias containedvscodehere 'newcontainerrw -v /tmp/.X11-unix/:/tmp/.X11-unix/ -v $HOME/.vscode:/tmp/.vscode:ro -v $HOME/projects/dotfiles/.config/Code:/tmp/.config-copyfrom:ro -v $HOME/.fonts:/tmp/.fonts:ro -v /etc/pacman.d/mirrorlist:/etc/pacman.d/mirrorlist:ro -e DISPLAY=:0 --entrypoint bash maowtm/vscode -c \'mkdir /tmp/.config && cp /tmp/.config-copyfrom /tmp/.config/Code -r && code --new-window --verbose /tmp/workspace\''
# Don't let others see our files.
umask 0027

function fish_greeting
end

abbr ga "git add"
abbr gc "git commit"
abbr gp "git push"
abbr g "git"
