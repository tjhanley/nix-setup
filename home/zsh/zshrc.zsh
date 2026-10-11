# History
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "$(dirname "$HISTFILE")" ]] || mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# Shell options
setopt auto_cd
setopt extended_glob
setopt correct

path_prepend_unique() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
}

# CLI completions — dump to fpath before compinit so they lazy-load correctly
_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_comp_cache"

if command -v kubectl >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_kubectl" ]] || kubectl completion zsh > "$_comp_cache/_kubectl"
fi
if command -v docker >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_docker" ]] || docker completion zsh > "$_comp_cache/_docker"
fi
if command -v mise >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_mise" ]] || mise completion zsh > "$_comp_cache/_mise"
fi
if command -v gh >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_gh" ]] || gh completion -s zsh > "$_comp_cache/_gh"
fi
if command -v stern >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_stern" ]] || stern --completion zsh > "$_comp_cache/_stern"
fi

fpath=("$_comp_cache" "$HOME/.nix-profile/share/zsh/site-functions" $fpath)
unset _comp_cache

# zsh completion core
autoload -Uz compinit
zmodload zsh/complist
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"

# Better completion UX
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf-tab completion menu (path injected by home/zsh.nix)
[[ -f "$_NIX_FZF_TAB" ]] && source "$_NIX_FZF_TAB"

# mise runtime manager
if [[ -z "$_MISE_INITIALIZED" ]] && command -v mise >/dev/null 2>&1; then
  _MISE_INITIALIZED=1
  eval "$(mise activate zsh)"
fi

# Rust toolchain
path_prepend_unique "$HOME/.cargo/bin"

# Local bin (mise shims, pipx, user scripts, etc.)
path_prepend_unique "$HOME/.local/bin"
path_prepend_unique "$HOME/.opencode/bin"

# Tool config paths
export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# FZF
if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.57 builds ctrl-r from zsh's $history parameter, which omits
  # commands imported from other sessions via share_history; disabling the
  # perl branch forces the fc-based fallback, which includes them
  source <(fzf --zsh | sed 's/(( ${+commands\[perl\]} ))/false/')
  export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
    --color=selected-bg:#45475A \
    --color=border:#6C7086,label:#CDD6F4"
fi

# Git aliases (OMZ-style)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gc='git commit'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias glog='git log --oneline --graph --decorate'
alias gloga='git log --oneline --graph --decorate --all'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gst='git status'
alias gsw='git switch'
alias gswc='git switch -c'

# Dot navigation (.., ..., ....)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias l='ls -lah'

# Editor defaults
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  alias vim='nvim'
  alias vi='nvim'
fi

# eza replaces ls (if installed)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -la --group-directories-first --icons=auto --git --header --time-style=relative'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto --git --git-ignore'
fi

# Common tool aliases
if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
  compdef y=yazi
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v zellij >/dev/null 2>&1; then
  alias zj='zellij'
  alias zja='zellij attach -c main'
  alias zka='zellij kill-all-sessions'
fi

if command -v docker >/dev/null 2>&1; then
  alias d='docker'
fi

if command -v lazydocker >/dev/null 2>&1; then
  alias lzd='lazydocker'
fi

# AI + cloud aliases
if command -v claude >/dev/null 2>&1; then
  alias cc='claude'
  alias ccw='claude --worktree'
fi

if command -v opencode >/dev/null 2>&1; then
  alias oc='opencode'
fi

if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
fi

alias awsdevx='aws sso login --profile devx-platform-dev'

# Apply this repo to the host
hms() { home-manager switch --flake "${NIX_SETUP_DIR:-$HOME/Workspace/nix-setup}#coder" "$@"; }

# Machine-specific secrets and overrides (not tracked in git)
if [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi

export AWS_PROFILE=225194532386_PowerUserAccess
# Credentials do NOT belong in this file: it is rendered from this repo into
# the nix store. Secrets live in ~/.secrets (outside the repo), sourced above.

# AWS SSO login + export creds for Terraform
awsl() {
  aws login --profile "$AWS_PROFILE" && \
  eval "$(aws configure export-credentials --profile "$AWS_PROFILE" --format env)" && \
  print -P "%F{green}✓%f AWS creds exported for $AWS_PROFILE"
}

# In zellij: tint the pane and set title "[ssh@host]" while ssh runs, then undo.
# Host is the last arg (user@ stripped); wrong if a remote command is passed.
ssh() {
  [[ -z "$ZELLIJ" ]] && { command ssh "$@"; return; }
  local host="${${@[-1]}#*@}"
  zellij action rename-pane "[ssh@$host]"
  zellij action set-pane-color --bg "#38395a"
  command ssh "$@"
  local rc=$?
  zellij action undo-rename-pane
  zellij action set-pane-color --reset
  return $rc
}

# Per-directory gh account. Exports GH_TOKEN so that both `gh` AND git use the
# right identity, without depending on the global `gh auth switch` state -- git
# routes github.com creds through `gh auth git-credential`, which honours
# GH_TOKEN over the active account. If the active account drifts, private repos
# 404 as "Repository not found", so nothing here falls back to it silently.
#
# Resolution order:  git config gh.user  ->  remote owner  ->  path default.

# GitHub owner -> gh account.
typeset -gA GH_ACCOUNT_BY_OWNER=(
  sonatus   tjhanley-snt
  snt-devx  tjhanley-snt
  tjhanley  tjhanley
)

# Fallback for directories that are not inside a git repo yet. This is what
# covers `git clone` of a private repo: there is no remote to derive from until
# the clone finishes, so the enclosing directory decides the identity.
typeset -gA GH_ACCOUNT_BY_PATH=(
  "$HOME/Workspace"  tjhanley-snt
)

typeset -gA _gh_token_cache _gh_warned_owners

# Owner from a remote URL. Handles https, scp-style ssh, and ssh host aliases:
#   https://github.com/sonatus/iac-live.git      -> sonatus
#   git@github.com:tjhanley/necronomicon.git     -> tjhanley
#   git@github.com-personal:tjhanley/mac-setup   -> tjhanley
_gh_remote_owner() {
  local url=${1#*://}   # strip scheme, if any
  url=${url#*@}         # strip user@, if any
  [[ $url == *[:/]* ]] || return 1
  local host=${url%%[:/]*} path=${url#*[:/]}
  [[ $host == github.com || $host == github.com-* ]] || return 1
  path=${path%%/*}
  [[ -n $path ]] && print -r -- $path
}

# These two helpers return values via $REPLY rather than stdout on purpose. A
# `$(...)` call would run them in a subshell, where writes to the cache and the
# warned-owners map are discarded -- which silently defeats both the token cache
# and the warn-once behaviour.

# Sets REPLY to the token for account $1. One `gh auth token` spawn per account
# per shell, not per cd.
_gh_token_for() {
  if [[ -z ${_gh_token_cache[$1]} ]]; then
    _gh_token_cache[$1]=$(gh auth token --user "$1" 2>/dev/null)
  fi
  REPLY=${_gh_token_cache[$1]}
  [[ -n $REPLY ]]
}

# Sets REPLY to the account for $PWD. Returns non-zero if none applies.
_gh_account_for_pwd() {
  local acct owner url dir
  REPLY=

  # 1. explicit per-repo override always wins
  acct=$(git config gh.user 2>/dev/null)
  [[ -n $acct ]] && { REPLY=$acct; return 0 }

  # 2. derive from the remote's owner
  url=$(git config remote.origin.url 2>/dev/null)
  if [[ -n $url ]] && owner=$(_gh_remote_owner "$url"); then
    acct=${GH_ACCOUNT_BY_OWNER[$owner]}
    [[ -n $acct ]] && { REPLY=$acct; return 0 }
    # A github.com remote we have no mapping for. Warn once per owner per shell
    # so an unmapped private repo does not present as a phantom 404.
    if [[ -o interactive && -z ${_gh_warned_owners[$owner]} ]]; then
      _gh_warned_owners[$owner]=1
      print -u2 "gh: no account mapped for owner '$owner'; using gh's active account"
    fi
    return 1
  fi

  # 3. not in a git repo with a github remote -- fall back on location
  for dir in ${(k)GH_ACCOUNT_BY_PATH}; do
    if [[ $PWD == $dir || $PWD == $dir/* ]]; then
      REPLY=${GH_ACCOUNT_BY_PATH[$dir]}
      return 0
    fi
  done
  return 1
}

_gh_set_token() {
  local acct
  if _gh_account_for_pwd; then
    acct=$REPLY
    if _gh_token_for "$acct"; then
      export GH_TOKEN=$REPLY
      return
    fi
    [[ -o interactive ]] &&
      print -u2 "gh: no stored token for '$acct'; run: gh auth login --user $acct"
  fi
  unset GH_TOKEN
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _gh_set_token
_gh_set_token

# Claude Code metering
if [ -f "$HOME/.claude/revenium.env" ]; then
    source "$HOME/.claude/revenium.env"
fi

unset -f path_prepend_unique
