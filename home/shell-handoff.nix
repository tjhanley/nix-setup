{ config, lib, ... }:
let
  cfg = config.setup.zshHandoff;
  marker = "# >>> nix-setup zsh handoff >>>";
in
{
  options.setup.zshHandoff = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Append a guarded `exec zsh` block to ~/.bashrc. The login shell on this
      host is bash and chsh would need the nix zsh listed in /etc/shells, so
      interactive bash hands off to zsh instead. NO_AUTO_ZSH=1 opts out per
      shell. Existing ~/.bashrc content is preserved; disabling the option
      does not remove the block.
    '';
  };

  config.home.activation.zshHandoff = lib.mkIf cfg (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      bashrc="$HOME/.bashrc"
      if ! grep -qF '${marker}' "$bashrc" 2>/dev/null; then
        if [[ -v DRY_RUN ]]; then
          echo "dry-run: append zsh handoff to $bashrc"
        else
          cat >> "$bashrc" <<'BLOCK'

      ${marker}
      if [ -z "$ZSH_VERSION" ] && [ -z "$NO_AUTO_ZSH" ] && [ -t 1 ] && [ -x "$HOME/.nix-profile/bin/zsh" ]; then
        exec "$HOME/.nix-profile/bin/zsh"
      fi
      # <<< nix-setup zsh handoff <<<
      BLOCK
        fi
      fi
    ''
  );
}
