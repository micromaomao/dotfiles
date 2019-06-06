set -x EDITOR 'vim'
set -x GOPATH /home/mao/go
set -x PATH $PATH:/usr/bin/core_perl/:~/npm-g/bin/:~/.cargo/bin
set PATH (echo "$PATH" | tr : \n | sort -u | head -c-1 | tr \n :) # Remove duplicates

set -g last_status 0

function show_time_of_exec -e fish_preexec
  echo -esn '\e[' (math $COLUMNS - 10) 'G\e[1A' (set_color yellow) (date +%T) '\e[0G\e[1B'
end

function show_exit_status -e fish_postexec
  set last_status $status
end

function fish_prompt --description 'Write out the prompt'
  set -l in_docker 0
  set -l color_hostname yellow
  if [ -e /.dockerenv ]
    set in_docker 1
    set color_hostname blue
  end
  set -l suffix ">"
  set -l color_username "blue"
  if [ "$USER" = "root" ]
    set suffix "#"
    set color_username "red"
  end

  if [ "$last_status" -ne 0 ]
    echo -n -s (set_color red) " ($last_status) "
  end

  set -l git_branch ''
  if [ -d .git ]
    set -l col blue
    set -l branch_name (cat .git/HEAD | string split --right -m 1 / | tail -n 1)
    set -l num_untracked (git ls-files -o --exclude-standard | wc -l)
    set -l num_modified (git diff --numstat --no-renames | wc -l)
    set git_branch "; "(set_color $col)"$branch_name"
    set -l total_modified (math $num_untracked + $num_modified)
    if [ $total_modified -gt 0 ]
      set git_branch $git_branch"; "(set_color green)$total_modified
    end
  end

  echo -sn (set_color $color_hostname) (prompt_hostname) (set_color yellow) " (" (set_color $color_username) $USER $git_branch (set_color yellow) ") " (set_color green) (prompt_pwd) "$suffix " (set_color normal)
end

function recitediff
  git diff --color-words --minimal -U100 $argv
end

if type -q exa
  alias ls exa
end

function newcontainer
  docker run \
    -it --entrypoint bash \
    -v (pwd):/tmp/workspace:ro \
    -w /tmp/workspace \
    -u (id -u):(id -g) \
    --rm $argv
end

function newcontainerrw
  docker run \
    -it --entrypoint bash \
    -v (pwd):/tmp/workspace \
    -v (pwd)/.git:/tmp/workspace/.git:ro \
    -v (pwd)/.vscode:/tmp/workspace/.vscode:ro \
    -w /tmp/workspace \
    -u (id -u):(id -g) \
    --rm $argv
end

alias diff "diff -u --color=always"

function httpserverhere
  : (sleep 1; xdg-open http://localhost:8000) & \
  newcontainer -p 127.0.0.1:8000:8000 python -c "python -m http.server"
end

function containedvscode
  if [ (count $argv) -eq 0 -o (count $argv) -gt 1 ]
    echo Usage: containedvscode '<dir>'
    return 1
  end
  cd {$argv[1]} || return 1
  set -l arr (pwd | tr '/' '\0' | string split0)
  set -l trname (echo -n {$arr[(count $arr)]})
  docker run -it \
    -v (pwd):"/tmp/$trname" \
    -w "/tmp/$trname" \
    -u (id -u):(id -g) \
    --rm \
    -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/run/user/1000/$WAYLAND_DISPLAY:ro -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY -e XDG_RUNTIME_DIR=/run/user/1000 \
    -v /tmp/.X11-unix/:/tmp/.X11-unix:ro -e DISPLAY=$DISPLAY \
    -v /usr/:/usr/:ro \
    -v /opt/:/opt/:ro \
    -v $HOME/.fonts:$HOME/.fonts:ro \
    -v $HOME/go:$HOME/_go:ro \
    -v $HOME/.rustup:$HOME/.rustup:ro \
    -v $HOME/.vscode:$HOME/.vscode:ro \
    -v /etc/ca-certificates/:/etc/ca-certificates/:ro \
    -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
    --entrypoint code maowtm/bare \
    --new-window --verbose .
  if [ -d .git ]
    set -l hookspath (git config --local --get core.hooksPath || echo .git/hooks/)
    chmod a-x -R $hookspath/*
  end
end

alias convert 'convert -limit memory 3G'

umask 0027

function fish_greeting
end

abbr ga "git add"
abbr gc "git commit"
abbr gp "git push"
abbr g "git"
