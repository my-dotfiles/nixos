{ config, lib, ... }:

let
  cfg = config.myHome.desktop.mime;
in
{
  options.myHome.desktop.mime.enable = lib.mkEnableOption "XDG MIME defaults";

  config = lib.mkIf cfg.enable {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/json" = [ "Helix.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
        "application/x-yaml" = [ "Helix.desktop" ];
        "image/apng" = [ "org.gnome.Loupe.desktop" ];
        "image/avif" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "inode/directory" = [ "thunar.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "text/markdown" = [ "Helix.desktop" ];
        "text/plain" = [ "Helix.desktop" ];
        "text/x-cmake" = [ "Helix.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/ogg" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      };
    };
  };
}
