{ config, lib, ... }:

let
  cfg = config.mySystem.core.nix;
in
{
  options.mySystem.core.nix.enable = lib.mkEnableOption "Nix daemon and nixpkgs defaults";

  config = lib.mkIf cfg.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      connect-timeout = 10;
      stalled-download-timeout = 60;
      download-attempts = 3;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
