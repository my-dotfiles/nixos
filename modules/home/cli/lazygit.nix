{ config, lib, ... }:

let
  cfg = config.myHome.cli.lazygit;
in
{
  options.myHome.cli.lazygit.enable = lib.mkEnableOption "lazygit terminal Git UI";

  config = lib.mkIf cfg.enable {
    programs.lazygit.enable = true;
  };
}
