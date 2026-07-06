{ ... }:

{
  imports = [
    ../core/nix.nix
    ../core/system.nix
    ../apps/homebrew.nix
  ];

  myDarwin.core.nix.enable = true;
  myDarwin.core.system.enable = true;
  myDarwin.apps.homebrew.enable = true;

  programs.fish.enable = true;
}
