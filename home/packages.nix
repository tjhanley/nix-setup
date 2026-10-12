{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Shell and prompt
    starship
    zoxide
    fzf
    zsh-fzf-tab

    # Core CLI
    bat
    btop
    duf
    dust
    eza
    fastfetch
    fd
    glow
    jq
    ripgrep
    tldr
    wget
    yazi

    # Git
    delta
    gh
    git
    git-lfs
    lazygit

    # Editor and terminal
    neovim
    (screen.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [ "--with-system_screenrc=/dev/null" ];
    }))
    tree-sitter
    zellij

    # Cloud and containers
    awscli2
    k9s
    kubectl
    lazydocker
    stern

    # Runtimes (mise installs node/python/ruby/go per config/mise)
    mise
    uv

    # AI
    opencode
  ];
}
