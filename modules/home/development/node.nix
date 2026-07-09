{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.node;
  npmPrefix = "${config.home.homeDirectory}/.npm-global";
  npmCache = "${config.home.homeDirectory}/.cache/npm";
in
{
  options.myHome.development.node.enable = lib.mkEnableOption "Node.js and npm configuration";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.nodejs
    ];

    home.sessionVariables = {
      NPM_CONFIG_PREFIX = npmPrefix;
      NPM_CONFIG_CACHE = npmCache;
    };

    home.file.".npmrc".text = ''
      prefix=${npmPrefix}
      cache=${npmCache}
      fund=false
      audit=false
      update-notifier=false
    '';

    home.file.".npm-global/.keep".text = "";
  };
}
