# nix-setup — Agent Guidelines

Nix flake + home-manager for the Linux VM host; counterpart of `~/Workspace/mac-setup`.

- Docs: any change to packages, options, modules or defaults updates `README.md` in the same commit.
- Verify with `nix flake check`. Nix is not installed on the host by default; run it in a container:
  `docker run --rm -v "$PWD":/src -w /src -e NIX_CONFIG='experimental-features = nix-command flakes' nixos/nix sh -c 'git config --global --add safe.directory /src && nix flake check'`
  (new files must be `git add`ed or the flake cannot see them).
- Never auto-start zellij by default: `setup.zellijAutostart` stays `false`; keep the flake checks that enforce it.
- No secrets or git identity in the repo (`~/.gitconfig.local`, `~/.secrets`).
- Theme: Catppuccin Latte. No emojis in code or docs.
- GitHub: `tjhanley` personal account (`gh auth switch --user tjhanley`).
