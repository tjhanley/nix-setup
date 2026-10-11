{ config, lib, pkgs, ... }:
let
  cfg = config.setup.zellijAutostart;
in
{
  options.setup.zellijAutostart = lib.mkEnableOption ''
    exec zellij from interactive zsh shells. Off by default; when on,
    NO_AUTO_ZELLIJ=1 opts a single shell out'';

  config.programs.zsh = {
    enable = true;
    # compinit is run by zshrc.zsh after fpath is extended
    enableCompletion = false;
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        _NIX_FZF_TAB=${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
      (builtins.readFile ./zsh/zshrc.zsh)
      (lib.mkIf cfg ''
        if command -v zellij >/dev/null 2>&1; then
          if [[ $- == *i* ]] && [[ -t 1 ]] && [[ -z "''${ZELLIJ:-}" ]] && [[ -z "''${TMUX:-}" ]] && [[ "''${NO_AUTO_ZELLIJ:-0}" != "1" ]]; then
            exec zellij
          fi
        fi
      '')
      # plugins load last
      (lib.mkAfter ''
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '')
    ];
  };
}
