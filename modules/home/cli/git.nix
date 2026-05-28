{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.git;
in
{
  options.myHome.cli.git = {
    enable = lib.mkEnableOption "Git command-line configuration";

    userName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git commit author name.";
    };

    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git commit author email.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      package = pkgs.git;

      settings = {
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
      }
      // lib.optionalAttrs (cfg.userName != null) {
        user.name = cfg.userName;
      }
      // lib.optionalAttrs (cfg.userEmail != null) {
        user.email = cfg.userEmail;
      };
    };
  };
}
