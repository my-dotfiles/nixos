{ config, lib, ... }:

let
  cfg = config.myHome.cli.btop;
in
{
  options.myHome.cli.btop.enable = lib.mkEnableOption "btop resource monitor";

  config = lib.mkIf cfg.enable {
    programs.btop.enable = true;
  };
}
