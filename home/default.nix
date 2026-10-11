{ ... }:
{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./git.nix
    ./files.nix
    ./shell-handoff.nix
  ];

  home = {
    username = "coder";
    homeDirectory = "/home/coder";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;
}
