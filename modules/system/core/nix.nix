{ config, lib, ... }:

let
  cfg = config.mySystem.core.nix;
in
{
  options.mySystem.core.nix.enable = lib.mkEnableOption "Nix daemon and nixpkgs defaults";

  config = lib.mkIf cfg.enable {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nixpkgs.config.allowUnfree = true;
  };
}
