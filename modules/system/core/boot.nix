{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.core.boot;
in
{
  options.mySystem.core.boot.enable = lib.mkEnableOption "boot loader and kernel defaults";

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      kernelPackages = pkgs.linuxPackages_latest;
    };
  };
}
