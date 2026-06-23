# PowerShell profile mimicking the fish prompt in .config/fish/config.fish

$env:EDITOR = 'vim'

# --- Color helpers (ANSI) ------------------------------------------------
$script:e = [char]27
function script:Color([string]$code) { "$($script:e)[$($code)m" }

$script:colReset   = Color '0'
$script:colRed     = Color '31'
$script:colGreen   = Color '32'
$script:colYellow  = Color '33'
$script:colBlue    = Color '34'
$script:colMagenta = Color '35'
$script:colCyan    = Color '36'
$script:colBrBlack = Color '90'
$script:colBrBlue  = Color '94'

# --- State tracking ------------------------------------------------------
$script:KubeStatus = ' '
$script:KubeFetchedTime = 0

function script:Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    } catch {
        return $false
    }
}

function script:Get-PromptHostname {
    if ($env:COMPUTERNAME) { return $env:COMPUTERNAME }
    return [System.Net.Dns]::GetHostName()
}

function script:Get-PromptPwd {
    $p = (Get-Location).Path
    $home_ = $HOME
    if ($home_ -and $p.StartsWith($home_, [System.StringComparison]::OrdinalIgnoreCase)) {
        $p = '~' + $p.Substring($home_.Length)
    }
    return $p
}

function script:Update-KubeStatus {
    $now = [int][double]::Parse((Get-Date -UFormat %s))
    if (($now - $script:KubeFetchedTime) -lt 5) { return }
    $script:KubeFetchedTime = $now
    $script:KubeStatus = ' '
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        $ctx = (kubectl config current-context 2>$null)
        if ($LASTEXITCODE -eq 0 -and $ctx) {
            $ns = (kubectl config view --minify --flatten -o "jsonpath={.contexts[?(@.name == `"$ctx`")].context.namespace}" 2>$null)
            if (-not $ns) { $ns = 'default' }
            $script:KubeStatus = ' ' + $script:colYellow + '(' + $script:colCyan + "$ctx/$ns" + $script:colYellow + ') '
        }
    }
}

function script:Get-GitSegment {
    $branch = (git branch --show-current 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $branch) { return '' }

    $seg = '; ' + $script:colBlue + $branch
    $hash = (git rev-parse --short HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $hash) {
        $seg += $script:colYellow + ' = ' + $script:colYellow + $hash
    }

    $untracked = @(git ls-files -o --exclude-standard 2>$null).Count
    $modified = @(git diff --numstat --no-renames 2>$null).Count
    $total = $untracked + $modified
    if ($total -gt 0) {
        $seg += ' ' + $script:colGreen + $total
    }
    return $seg
}

function script:Get-DurationSegment {
    $h = Get-History -Count 1
    if (-not $h) { return '' }
    $diffMs = ($h.EndExecutionTime - $h.StartExecutionTime).TotalMilliseconds
    if ($diffMs -ge 60000) {
        $mins = [math]::Floor($diffMs / 60000)
        $secs = [math]::Floor(($diffMs % 60000) / 1000)
        return $script:colMagenta + "(${mins}m${secs}s) "
    }
    $secs = [math]::Floor($diffMs / 1000)
    return $script:colMagenta + "(${secs}s) "
}

function prompt {
    $lastOk = $?
    $lastExit = $LASTEXITCODE

    $isAdmin = script:Test-IsAdmin
    $suffix = if ($isAdmin) { 'PS#' } else { 'PS>' }
    $colUser = if ($isAdmin) { $script:colRed } else { $script:colBlue }

    # Simple prompt mode
    if ($env:USE_SIMPLE_PROMPT -eq 'true') {
        $s = if ($isAdmin) { 'PS#' } else { 'PS$' }
        return "$($script:colGreen)$s $($script:colReset)"
    }

    $out = ''

    # Virtual env
    if ($env:VIRTUAL_ENV) {
        $venv = Split-Path -Leaf $env:VIRTUAL_ENV
        $out += "$($script:colBrBlue)($venv)$($script:colReset) "
    }

    # Last status. Gate on $? (whether the last command actually failed)
    # rather than $LASTEXITCODE, which is left stale by cmdlets like cd and
    # gets clobbered by the git calls this prompt itself runs.
    if (-not $lastOk) {
        $code = if ($null -ne $lastExit -and $lastExit -ne 0) { $lastExit } else { 1 }
        $out += "$($script:colRed) ($code) "
    }

    # Command duration
    $out += script:Get-DurationSegment

    $colHostname = if ($env:USE_DOCKER_PROMPT_COLOR -eq 'true') { $script:colBlue } else { $script:colYellow }

    script:Update-KubeStatus

    $out += $colHostname + (script:Get-PromptHostname)
    $out += $script:colYellow + ' (' + $colUser + $env:USERNAME
    $out += script:Get-GitSegment
    $out += $script:colYellow + ')'
    $out += $script:KubeStatus
    $out += $script:colGreen + (script:Get-PromptPwd)
    $out += "`n$suffix $($script:colReset)"

    # Restore the user's exit code so the git/kubectl commands run above by
    # this prompt don't leak their exit codes into the next prompt render.
    $global:LASTEXITCODE = $lastExit
    return $out
}

# --- Git aliases / functions --------------------------------------------
function g { git @args }
function ga { git add @args }
function gc { git commit -v @args }
function gp { git push -v @args }

function glf {
    git log --format='%C(Yellow)%h %>(30)%C(reset)%ad %C(Cyan)%<|(53,trunc)%an %C(auto)%(decorate) %C(bold)%s' @args
}

function glfc {
    $hh = git log --color=always --format='%C(Yellow)%h %>(30)%C(reset)%ad %C(Cyan)%<|(53,trunc)%an %C(auto)%(decorate) %C(bold)%s' @args |
        Select-Object -First 1000 |
        fzf --ansi --no-sort --height=~20 --layout=reverse --no-multi --accept-nth=1
    if ($LASTEXITCODE -eq 0 -and $hh) {
        git checkout $hh
    }
}

function grbi {
    $hh = git log --color=always --format='%C(Yellow)%h %>(30)%C(reset)%ad %C(Cyan)%<|(53,trunc)%an %C(auto)%(decorate) %C(bold)%s' @args |
        Select-Object -First 1000 |
        fzf --ansi --no-sort --height=~20 --layout=reverse --no-multi --accept-nth=1
    if ($LASTEXITCODE -eq 0 -and $hh) {
        git rebase -i --autosquash --autostash --rebase-merges $hh
    }
}

function gb {
    git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname)' refs/heads refs/tags refs/remotes | less
}

function grf {
    git reflog --format='%C(bold)%C(Yellow)%h %C(reset)%>(15)%cr %C(auto)%(decorate) %C(Cyan)%gs%C(reset): %<(30,trunc)%C(bold)%s' @args
}

function grfc {
    $hh = git reflog --color=always --format='%C(bold)%C(Yellow)%h %C(reset)%>(15)%cr %C(auto)%(decorate) %C(Cyan)%gs%C(reset): %<(30,trunc)%C(bold)%s' @args |
        Select-Object -First 1000 |
        fzf --ansi --no-sort --height=~20 --layout=reverse --no-multi --accept-nth=1
    if ($LASTEXITCODE -eq 0 -and $hh) {
        git checkout $hh
    }
}

function recitediff {
    git diff --color-words --minimal -U100 @args
}

function k { kubectl @args }
