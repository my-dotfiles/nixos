{ config, lib, ... }:

let
  cfg = config.myHome.cli.prompt;
in
{
  options.myHome.cli.prompt.enable = lib.mkEnableOption "starship prompt";

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      settings.add_newline = false;
    };
  };
}
