{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.myDarwin.core.nix;
in
{
  options.myDarwin.core.nix.enable = lib.mkEnableOption "Nix daemon and nixpkgs defaults";

  config = lib.mkIf cfg.enable {
    nix = {
      enable = true;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://mirrors.ustc.edu.cn/nix-channels/store"
        ];

        trusted-users = [
          "yurikon"
          "@admin"
        ];

        extra-platforms = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];

        connect-timeout = 15;
        download-attempts = 5;
        max-jobs = "auto";
      };

      registry.nixpkgs.flake = inputs.nixpkgs;
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    };

    nixpkgs.config.allowUnfree = true;
  };
}
