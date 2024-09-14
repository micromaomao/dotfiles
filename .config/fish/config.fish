set -x EDITOR 'vim'
set -x PATH $PATH $HOME/npm-g/bin/ $HOME/.cargo/bin
set -x PATH $PATH $HOME/.bin
# set PATH (echo "$PATH" | tr : \n | sort -u | head -c-1 | tr \n :) # Remove duplicates

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

  set -l kube_status " "
  if type -q kubectl
    set -l kube_ctx (kubectl config current-context 2>/dev/null)
    set -l kube_ns ""
    if [ $status -eq 0 ]
      set kube_ns (kubectl config view --minify --flatten -o jsonpath='{.contexts[?(@.name == "'$kube_ctx'")].context.namespace}' 2>/dev/null)
      if [ $status -ne 0 ]
        set kube_ns (set_color red)"?"
      else if [ "$kube_ns" = "" ]
        set kube_ns "default"
      end
      set kube_status "$kube_status"(set_color yellow)"("(set_color cyan)$kube_ctx/$kube_ns(set_color yellow)") "
    end
  end
  echo -sn (set_color $color_hostname) (prompt_hostname) (set_color yellow) " (" (set_color $color_username) $USER $git_branch (set_color yellow) ")" $kube_status (set_color green) (prompt_pwd)
  echo
  echo -sn "$suffix " (set_color normal)
end

function fish_right_prompt
  # if [ "$USE_SIMPLE_PROMPT" != "true" -a "$last_exec_time" != "" ]
  #   echo -sn (set_color yellow) $last_exec_time " " (set_color normal)
  #   set last_exec_time ""
  # end
end

function fish_title
  echo (status current-command) - (__fish_pwd)'@'(prompt_hostname)
end

function recitediff
  git diff --color-words --minimal -U100 $argv
end

alias diff "diff -u --color=always"
alias convert 'convert -limit memory 3G'

umask 0027

function fish_greeting
end

abbr ga "git add"
abbr gc "git commit -v"
abbr gp "git push -v"
abbr g "git"

if type -q exa
  abbr ls exa
end

abbr k kubectl

set -x BAT_THEME ansi-light

# abbr firejail "env GTK_IM_MODULE=xim firejail"
