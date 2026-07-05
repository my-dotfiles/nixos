{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.services.flatpak;
  flathubRepo = pkgs.fetchurl {
    url = "https://flathub.org/repo/flathub.flatpakrepo";
    sha256 = "0fm0zvlf4fipqfhazx3jdx1d8g0mvbpky1rh6riy3nb11qjxsw9k";
  };
in
{
  options.mySystem.services.flatpak.enable = lib.mkEnableOption "Flatpak application runtime";

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.systemPackages = [
      pkgs.flatpak
    ];

    system.activationScripts.flatpakFlathubRemote.text = ''
      if [ -x ${lib.getExe pkgs.flatpak} ]; then
        ${lib.getExe pkgs.flatpak} remote-add --system --if-not-exists flathub ${flathubRepo}
      fi
    '';
  };
}
