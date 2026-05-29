{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.prompt;
  starshipCfg = config.programs.starship;
  gruvboxRainbowConfig = pkgs.runCommand "starship-gruvbox-rainbow.toml" { } ''
    ${lib.getExe starshipCfg.package} preset gruvbox-rainbow > $out
  '';
in
{
  options.myHome.cli.prompt.enable = lib.mkEnableOption "starship prompt";

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    home.file.${starshipCfg.configPath}.source = gruvboxRainbowConfig;
  };
}
