{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.core.locale;
in
{
  options.mySystem.core.locale.enable = lib.mkEnableOption "Chinese locale and input method";

  config = lib.mkIf cfg.enable {
    time.timeZone = "Asia/Shanghai";

    i18n = {
      defaultLocale = "zh_CN.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "zh_CN.UTF-8";
        LC_IDENTIFICATION = "zh_CN.UTF-8";
        LC_MEASUREMENT = "zh_CN.UTF-8";
        LC_MONETARY = "zh_CN.UTF-8";
        LC_NAME = "zh_CN.UTF-8";
        LC_NUMERIC = "zh_CN.UTF-8";
        LC_PAPER = "zh_CN.UTF-8";
        LC_TELEPHONE = "zh_CN.UTF-8";
        LC_TIME = "zh_CN.UTF-8";
      };

      inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            emacs-pgtk
            qt6Packages.fcitx5-chinese-addons
            fcitx5-gtk
            fcitx5-rime
            fcitx5-mozc
          ];
        };
      };
    };

    services.xserver.xkb = {
      layout = "us";
      options = "ctrl:nocaps";
    };
  };
}
