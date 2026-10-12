{
  description = "tjhanley's Nix + home-manager host setup (counterpart of mac-setup)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHome = extra: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home ] ++ extra;
      };
      home = mkHome [ ];
      screens = builtins.filter (p: (p.pname or "") == "screen") home.config.home.packages;
    in
    {
      homeConfigurations.coder = home;

      checks.${system} = {
        # zellij must never auto-start unless setup.zellijAutostart is set
        no-zellij-autostart-by-default = pkgs.runCommand "no-zellij-autostart-by-default" { } ''
          if grep -q 'exec zellij' ${pkgs.writeText "zshrc" home.config.programs.zsh.initContent}; then
            echo "zshrc execs zellij by default" >&2
            exit 1
          fi
          touch $out
        '';
        # screen sets TERM=screen*; forcing xterm-256color there breaks prompt and colors
        term-not-forced-in-screen = pkgs.runCommand "term-not-forced-in-screen" { } ''
          if grep -qE '^export TERM=' ${pkgs.writeText "zshrc" home.config.programs.zsh.initContent}; then
            echo "zshrc exports TERM unconditionally" >&2
            exit 1
          fi
          grep -q '^term screen-256color' ${home.config.home.file.".screenrc".source}
          touch $out
        '';
        # starship's palette is 24-bit; screen 4.x renders 38;2;r;g;b as dim
        screen-truecolor =
          let ok = screens != [ ] && builtins.all (p: nixpkgs.lib.versionAtLeast p.version "5") screens; in
          pkgs.runCommand "screen-truecolor" { } ''
            ${if ok then "" else ''echo "home.packages lacks screen >= 5" >&2; exit 1''}
            grep -q '^truecolor on' ${home.config.home.file.".screenrc".source}
            touch $out
          '';
        # Ubuntu's /etc/screenrc uses 4.x-only commands (deflogin, login) that screen 5 rejects
        screen-ignores-etc-screenrc = pkgs.runCommand "screen-ignores-etc-screenrc" { } ''
          for s in ${toString screens}; do
            if grep -aq /etc/screenrc $s/bin/screen; then
              echo "$s reads /etc/screenrc" >&2
              exit 1
            fi
          done
          touch $out
        '';
        zellij-autostart-opt-in =
          let optIn = mkHome [ { setup.zellijAutostart = true; } ]; in
          pkgs.runCommand "zellij-autostart-opt-in" { } ''
            grep -q 'exec zellij' ${pkgs.writeText "zshrc" optIn.config.programs.zsh.initContent}
            touch $out
          '';
      };
    };
}
