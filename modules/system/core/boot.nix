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
        systemd-boot = {
          enable = true;
          configurationLimit = 15;
        };
        efi.canTouchEfiVariables = true;
      };
      # Prefer the nixpkgs default kernel over the newest release line. This
      # reduces kernel/NVIDIA regressions on a long-lived workstation.
      kernelPackages = pkgs.linuxPackages;
    };
  };
}
