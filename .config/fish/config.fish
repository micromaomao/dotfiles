set -x EDITOR 'vim'
set -x GOPATH /home/mao/go
set -x PATH $PATH $HOME/npm-g/bin/ $HOME/.cargo/bin /usr/bin/vendor_perl/
set PATH (echo "$PATH" | tr : \n | sort -u | head -c-1 | tr \n :) # Remove duplicates

set -g last_status 0

# Compatibility
type -q prompt_hostname; or \
  function prompt_hostname
    cat /etc/hostname | tr -d \n
  end

function show_time_of_exec -e fish_preexec
  if [ "$USE_SIMPLE_PROMPT" = "true" ]
    return
  end
  echo -esn '\e[' (math $COLUMNS - 10) 'G\e[1A' (set_color yellow) (date +%T) '\e[0G\e[1B\e[0m'
end

function show_exit_status -e fish_postexec
  set last_status $status
end

function fish_prompt
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

  if [ "$USE_SIMPLE_PROMPT" = "true" ]
    if [ $USER != "root" ]
      set suffix "\$"
    end
    echo -sn (set_color green) "$suffix " (set_color normal)
    return
  end

  if [ "$last_status" -ne 0 ]
    echo -n -s (set_color red) " ($last_status) "
  end

  set -l git_branch ''
  if [ -d .git ]
    set -l col blue
    set -l branch_name (cat .git/HEAD | string split --right -m 1 / | tail -n 1)
    set git_branch "; "(set_color $col)"$branch_name"
    set -g __git_timeouted 0
    set -l total_modified 0
    set -l num_modified 0
    function with_timeout
      timeout --foreground -s INT 0.05 $argv
      if [ "$status" -ne 0 ]
        set __git_timeouted 1
        return 1
      end
    end
    set -l num_untracked (with_timeout git ls-files -o --exclude-standard | wc -l)
    if [ "$__git_timeouted" -eq 0 ]
      set num_modified (with_timeout git diff --numstat --no-renames | wc -l)
    end
    if [ "$__git_timeouted" -eq 0 ]
      set total_modified (math "$num_untracked" + "$num_modified")
    else
      set total_modified 0
    end
    if [ "$total_modified" -gt 0 ]
      set git_branch $git_branch"; "(set_color green)$total_modified
    else if [ "$__git_timeouted" -ne 0 ]
      set git_branch $git_branch"; "(set_color blue)"?"
    end
  end

  echo -sn (set_color $color_hostname) (prompt_hostname) (set_color yellow) " (" (set_color $color_username) $USER $git_branch (set_color yellow) ") " (set_color green) (prompt_pwd) "$suffix " (set_color normal)
end

function fish_title
  echo (status current-command) - (__fish_pwd)'@'(prompt_hostname)
end

function recitediff
  git diff --color-words --minimal -U100 $argv
end

# if type -q exa
#   alias ls exa
# end

function newcontainerro
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
    -w /tmp/workspace \
    -u (id -u):(id -g) \
    --rm $argv
end

alias diff "diff -u --color=always"

function httpserverhere
  : (sleep 1; xdg-open http://localhost:8000) & \
  newcontainerro -p 127.0.0.1:8000:8000 python -c "python -m http.server"
end

function containedguishell
  if [ (count $argv) -eq 0 -o (count $argv) -gt 1 ]
    echo Usage: containedvscode '<dir>'
    return 1
  end
  cd {$argv[1]}; or return 1
  set -l arr (pwd | tr '/' '\0' | string split0)
  set -l trname (echo -n {$arr[(count $arr)]})
  docker run -it \
    -v (pwd):"/tmp/$trname" \
    -w "/tmp/$trname" \
    -u 1000:1000 \
    --rm \
    -e XDG_RUNTIME_DIR=/run/user/1000 \
    -v /tmp/.X11-unix/:/tmp/.X11-unix:ro -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 -e _X11_NO_MITSHM=1 -e _MITSHM=0 \
    -v /usr/:/usr/:ro \
    -v /opt/:/opt/:ro \
    -v $HOME/.fonts:$HOME/.fonts:ro \
    -v /etc/fonts/:/etc/fonts/:ro \
    -v $HOME/go:$HOME/_go:ro \
    -v $HOME/.rustup:$HOME/.rustup:ro \
    -v $HOME/.vscode:$HOME/_vscode:ro \
    -v $HOME/.vim:$HOME/.vim:ro \
    -v /etc/ca-certificates/:/etc/ca-certificates/:ro \
    -v /etc/ssl/certs/:/etc/ssl/certs/:ro \
    -v /etc/java-8-openjdk/:/etc/java-8-openjdk/:ro \
    -v /var/lib/texmf/:/var/lib/texmf/:ro \
    -v /etc/texmf/:/etc/texmf/:ro \
    --device=/dev/dri/renderD128:/dev/dri/renderD128 \
    --entrypoint fish maowtm/bare -C ". /entrypoint.sh"
end

alias convert 'convert -limit memory 3G'

umask 0027

function fish_greeting
end

abbr ga "git add"
abbr gc "git commit -v"
abbr gp "git push -v"
abbr g "git"

set -x BAT_THEME ansi-light
