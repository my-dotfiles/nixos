{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myDarwin.core.nix;
in
{
  options.myDarwin.core.nix.enable = lib.mkEnableOption "Nix daemon and nixpkgs defaults";

  config = lib.mkIf cfg.enable {
    nix = {
      package = pkgs.nix;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "@admin"
          "yurikon"
        ];
      };
    };

    nixpkgs.config.allowUnfree = true;
  };
}
