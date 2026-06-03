{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.secrets.sops;
in
{
  options.myHome.secrets.sops.enable =
    lib.mkEnableOption "user secrets managed by sops-nix";
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.age
      pkgs.sops
    ];
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ../../../secrets/user.yaml;
      secrets.openrouter-api-key = { };
    };

    xdg.configFile."secrets/api-keys.fish".text = ''
      if test -r ${config.sops.secrets.openrouter-api-key.path}
        set -gx OPENROUTER_API_KEY \
          (string trim < ${config.sops.secrets.openrouter-api-key.path})
        end
      '';

    xdg.configFile."secrets/api-keys.bash".text = ''
      if [ -r ${config.sops.secrets.openrouter-api-key.path} ]; then
        export OPENROUTER_API_KEY="$(tr -d '\n' < ${config.sops.secrets.openrouter-api-key.path})"
      fi
    '';
  };
}
