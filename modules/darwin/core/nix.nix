{
  config,
  lib,
  ...
}:

let
  cfg = config.myDarwin.core.nix;
in
{
  options.myDarwin.core.nix.enable = lib.mkEnableOption "Nix daemon and nixpkgs defaults";

  config = lib.mkIf cfg.enable {
    # Determinate Nix manages its own daemon and nix.conf. Let it own the Nix
    # installation, while nix-darwin continues to manage the macOS system.
    nix.enable = false;

    nixpkgs.config.allowUnfree = true;
  };
}
