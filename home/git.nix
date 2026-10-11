{ pkgs, ... }:
let
  ghCred = "!${pkgs.gh}/bin/gh auth git-credential";
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    # user.name / user.email live in ~/.gitconfig.local (host-specific)
    includes = [ { path = "~/.gitconfig.local"; } ];
    settings = {
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        pager = "delta";
      };
      pull.rebase = true;
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      fetch.prune = true;
      alias = {
        delete-local-merged = "!git fetch && git branch --merged | egrep -v 'master|dev|main|staging' | xargs git branch -d";
        branches = "for-each-ref --sort=-committerdate --format=\"%(color:blue)%(authordate:relative)\t%(color:red)%(authorname)\t%(color:white)%(color:bold)%(refname:short)\" refs/remotes";
        praise = "blame";
      };
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      credential."https://github.com".helper = [ "" ghCred ];
      credential."https://gist.github.com".helper = [ "" ghCred ];
    };
  };
}
