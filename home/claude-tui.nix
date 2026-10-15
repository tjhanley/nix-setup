{ pkgs, ... }:
let
  claude-tui = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "claude-tui";
    version = "0.8.9";

    src = pkgs.fetchFromGitHub {
      owner = "slima4";
      repo = "claude-tui";
      rev = "v${version}";
      hash = "sha256-cualWHZY7p2SSqO32cSTSQ1hijD7SevOuh6Ag/gng8o=";
    };

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/claude-tui $out/bin
      cp -r . $out/share/claude-tui
      cat > $out/bin/claudetui <<WRAPPER
      #!${pkgs.runtimeShell}
      exec ${pkgs.python313}/bin/python3 $out/share/claude-tui/claudetui.py "\$@"
      WRAPPER
      chmod +x $out/bin/claudetui
    '';
  };
in
{
  home.packages = [ claude-tui ];

  # statusLine and hooks in ~/.claude/settings.json call `claudetui` from PATH;
  # that file is mutable state and is configured with `claudetui setup`/`mode`.
  home.file.".claude/commands/tui".source = "${claude-tui}/share/claude-tui/claude-code-commands/tui";
}
