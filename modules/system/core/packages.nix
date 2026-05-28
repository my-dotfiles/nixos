{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.core.packages;
in
{
  options.mySystem.core.packages.enable = lib.mkEnableOption "base system packages";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      curl
      tree
      unzip
      file
      parted
      pciutils
      usbutils
      gparted
      flclash
    ];

    programs.firefox.enable = true;
  };
}
