{ ... }:

{
  imports = [
    ./base.nix
    ../desktop/niri.nix
  ];

  mySystem = {
    core = {
      boot.enable = true;
      locale.enable = true;
      networking.enable = true;
      nix.enable = true;
      packages.enable = true;
      users.enable = true;
    };

    desktop.niri.enable = true;
    desktop.thunar.enable = true;

    services = {
      openssh.enable = true;
      pipewire.enable = true;
      printing.enable = true;
      proxy.enable = true;
    };
  };
}
