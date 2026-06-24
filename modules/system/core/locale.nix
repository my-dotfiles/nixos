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
  options.mySystem.core.locale.enable =
    lib.mkEnableOption "English system language with Chinese regional formats and input method";

  config = lib.mkIf cfg.enable {
    time.timeZone = "Asia/Shanghai";

    i18n = {
      defaultLocale = "en_US.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "zh_CN.UTF-8";
        LC_COLLATE = "en_US.UTF-8";
        LC_IDENTIFICATION = "zh_CN.UTF-8";
        LC_MEASUREMENT = "zh_CN.UTF-8";
        LC_MESSAGES = "en_US.UTF-8";
        LC_MONETARY = "zh_CN.UTF-8";
        LC_NAME = "zh_CN.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
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
            fcitx5-mellow-themes
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

    environment.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      INPUT_METHOD = "fcitx";
      SDL_IM_MODULE = "fcitx";
    };
  };
}
