{ config, lib, ... }:

let
  cfg = config.myDarwin.core.system;
in
{
  options.myDarwin.core.system.enable = lib.mkEnableOption "macOS system defaults";

  config = lib.mkIf cfg.enable {
    system = {
      primaryUser = "yurikon";
      stateVersion = 6;

      defaults = {
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          ApplePressAndHoldEnabled = false;
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
        };

        dock = {
          autohide = true;
          expose-group-apps = true;
          mineffect = "scale";
          minimize-to-application = true;
          mru-spaces = false;
          show-recents = false;
          showhidden = true;
          tilesize = 51;
        };

        finder = {
          AppleShowAllExtensions = true;
          FXDefaultSearchScope = "SCcf";
          FXEnableExtensionChangeWarning = false;
          FXPreferredViewStyle = "Nlsv";
          QuitMenuItem = true;
          ShowPathbar = true;
          ShowStatusBar = true;
          _FXShowPosixPathInTitle = true;
          _FXSortFoldersFirst = true;
        };

        loginwindow = {
          GuestEnabled = false;
          SHOWFULLNAME = false;
        };

        menuExtraClock = {
          Show24Hour = true;
          ShowDate = 1;
          ShowDayOfWeek = true;
        };

        screencapture = {
          disable-shadow = true;
          include-date = true;
          show-thumbnail = false;
          target = "file";
          type = "png";
        };

        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
          TrackpadThreeFingerDrag = true;
        };
      };
    };
  };
}
