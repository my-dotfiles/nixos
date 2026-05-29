{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.github;
in
{
  options.myHome.cli.github.enable = lib.mkEnableOption "GitHub CLI configuration";

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
      package = pkgs.gh;
      settings = {
        git_protocol = "ssh";
        aliases.co = "pr checkout";
      };
    };
  };
}
