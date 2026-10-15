# nix-setup

Nix + home-manager setup for Linux hosts, the counterpart of
[mac-setup](https://github.com/tjhanley/mac-setup). Same shell, prompt, git and
CLI tooling, same Catppuccin Latte theming, declared in a flake instead of
Homebrew + Stow.

Target: `coder@x86_64-linux` (Ubuntu VM host). Login shell stays bash; interactive
bash hands off to zsh (see below).

## Quick start

```sh
git clone https://github.com/tjhanley/nix-setup ~/Workspace/nix-setup
cd ~/Workspace/nix-setup
./setup.sh --dry-run   # preview
./setup.sh
```

`setup.sh` installs Nix (multi-user, needs sudo) if missing, enables flakes, then
runs `home-manager switch --flake .#coder -b bak`. Pre-existing dotfiles are kept
as `*.bak`. After the first run, `hms` (zsh function) re-applies the repo.

## Defaults worth knowing

| Option | Default | Effect |
|--------|---------|--------|
| `setup.zellijAutostart` | `false` | zellij is installed and configured but never started automatically. Set `true` in `home/default.nix` to `exec zellij` from interactive zsh (`NO_AUTO_ZELLIJ=1` opts out per shell). |
| `setup.zshHandoff` | `true` | Appends a guarded `exec zsh` block to `~/.bashrc` (existing content kept). `NO_AUTO_ZSH=1 bash` stays in bash. |

zsh is the shell on this host in practice, but the account's login shell is bash
and zsh is not installed by apt. Rather than `chsh` to a nix path (needs an
`/etc/shells` entry), bash hands off to the nix zsh.

## Layout

```
flake.nix               inputs (nixpkgs unstable, home-manager), homeConfigurations.coder, checks
setup.sh                bootstrap (install nix, enable flakes, switch)
home/
  default.nix           imports + user/home/stateVersion
  packages.nix          CLI tools (mac-setup Brewfile equivalents)
  zsh.nix               programs.zsh, plugins, zellijAutostart option
  zsh/zshrc.zsh         the zshrc, adapted from mac-setup
  git.nix               git config (identity stays in ~/.gitconfig.local)
  files.nix             config files linked into ~/.config, bat theme
  claude-tui.nix        claudetui (slima4/claude-tui) pinned to a release, plus ~/.claude/commands/tui
  shell-handoff.nix     bash -> zsh handoff
config/                 vendored app configs (starship, eza, lazygit, yazi, mise, zellij, ripgrep, git ignore)
```

## claude-tui

[claude-tui](https://github.com/slima4/claude-tui) (statusline, live monitor, session
stats, `/tui:*` slash commands) is built from a pinned release in `home/claude-tui.nix`.
The `claudetui` wrapper runs under Nix `python313`, because claude-tui needs Python 3.13+
and the host `python3` is 3.12. The `/tui:*` commands are linked to
`~/.claude/commands/tui`.

`~/.claude/settings.json` is mutable state and is not managed here. Its `statusLine` and
hooks call `claudetui` from `PATH`; configure them once with `claudetui setup` (or edit
by hand) and switch styles with `claudetui mode full|compact|custom`. To upgrade, bump
`version` and `hash` in `home/claude-tui.nix`.

## mac-setup mapping

| mac-setup | here |
|-----------|------|
| Brewfile CLI tools | `home/packages.nix` |
| `stow/zsh/.zshrc` | `home/zsh/zshrc.zsh` + `home/zsh.nix` |
| `stow/git/.gitconfig` | `home/git.nix` |
| stow packages bat, eza, lazygit, ripgrep, starship, yazi, mise | `home/files.nix` + `config/` |
| `stow/zellij` | minimal `config/zellij/config.kdl` (built-in `catppuccin-latte`) |
| `~/.mac-setup.local` feature flags | Nix options under `setup.*` |
| `~/.bashrc` TERM export and `claude` intake wrapper | `home/zsh/zshrc.zsh` (TERM is left alone inside screen/tmux) |
| (host only) GNU screen settings | `screen` 5.x in `home/packages.nix` + `config/screen/screenrc` -> `~/.screenrc` (UTF-8, `screen-256color`, `truecolor on`, `defbce`). The system `/usr/bin/screen` 4.x has no 24-bit color and its sessions live in `/run/screen`; the Nix screen uses `~/.screen`. The Nix screen is built to skip `/etc/screenrc` (Ubuntu's uses 4.x-only commands); its still-valid defaults (safety key unbinds, `defnonblock`, title hardstatus) are carried in `~/.screenrc` |

Not ported (macOS-only or host-specific): ghostty, karabiner, skhd, zed, obsidian,
ssh (1Password agent), the zjstatus bar and its macOS scripts, the zellij nav
plugins, LazyVim bootstrap and nvim overrides, Dashlane `refresh-secrets`,
caffeinate helpers, Homebrew, fonts, AI-tool configs (claude, pi, opencode).
Neovim is installed but unconfigured.

Host-specific state stays out of the repo: git identity in `~/.gitconfig.local`
(the existing `~/.gitconfig` keeps working), secrets in `~/.secrets`.

## GitHub identity

The zshrc exports `GH_TOKEN` per directory (git config `gh.user`, then the remote
owner, then a path default) so `gh` and git use the right account regardless of
`gh auth switch` state. `GH_TOKEN` makes `gh auth refresh|login|switch|logout`
refuse to run, so a `gh` shell function drops it for `gh auth ...` only; those
commands act on the stored login. Re-export happens on the next `cd` or new shell.

## Development

```sh
nix flake check                                   # includes the zellij-autostart checks
nix build .#homeConfigurations.coder.activationPackage
```

Verified in a `nixos/nix` container (evaluation, build, activation twice for
idempotence, zsh startup with `TERM_PROGRAM=ghostty` leaves `$ZELLIJ` unset).
Applied to the `coder` VM host.
