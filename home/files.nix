{ pkgs, ... }:
{
  xdg.configFile = {
    "starship.toml".source = ../config/starship/starship.toml;
    "eza/theme.yml".source = ../config/eza/theme.yml;
    "lazygit/config.yml".source = ../config/lazygit/config.yml;
    "yazi/theme.toml".source = ../config/yazi/theme.toml;
    "yazi/Catppuccin-mocha.tmTheme".source = ../config/yazi/Catppuccin-mocha.tmTheme;
    "mise/config.toml".source = ../config/mise/config.toml;
    "zellij/config.kdl".source = ../config/zellij/config.kdl;
    "git/ignore".source = ../config/git/ignore;
  };

  home.file.".ripgreprc".source = ../config/ripgrep/ripgreprc;

  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Mocha";
      style = "numbers,changes,header";
      italic-text = "always";
    };
    themes."Catppuccin Mocha" = {
      src = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "bat";
        rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
        hash = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
      };
      file = "themes/Catppuccin Mocha.tmTheme";
    };
  };
}
