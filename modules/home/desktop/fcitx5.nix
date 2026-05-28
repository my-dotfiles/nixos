{ config, lib, ... }:

let
  cfg = config.myHome.desktop.fcitx5;
in
{
  options.myHome.desktop.fcitx5.enable = lib.mkEnableOption "fcitx5 user configuration";

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      INPUT_METHOD = "fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    xdg.configFile."fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=pinyin

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=pinyin
      Layout=

      [GroupOrder]
      0=Default
    '';

    xdg.configFile."fcitx5/config".text = ''
      [Hotkey]
      EnumerateWithTriggerKeys=True
      EnumerateSkipFirst=False
      ModifierOnlyKeyTimeout=251

      [Hotkey/TriggerKeys]
      0=Super+Num_Lock

      [Hotkey/EnumerateForwardKeys]
      0=Control+space

      [Hotkey/PrevCandidate]
      0=Shift+Tab

      [Hotkey/NextCandidate]
      0=Tab

      [Behavior]
      ActiveByDefault=False
      resetStateWhenFocusIn=No
      ShareInputState=No
      PreeditEnabledByDefault=True
      ShowInputMethodInformation=True
      CompactInputMethodInformation=True
      DefaultPageSize=5
      PreloadInputMethod=True
      AllowInputMethodForPassword=False
      AutoSavePeriod=30
    '';

    xdg.configFile."fcitx5/conf/pinyin.conf".text = ''
      ShuangpinProfile=Ziranma
      ShowShuangpinMode=True
      PageSize=7
      SpellEnabled=True
      SymbolsEnabled=True
      ChaiziEnabled=True
      ExtBEnabled=True
      CloudPinyinEnabled=True
      CloudPinyinIndex=2
      PreeditMode="Composing pinyin"
      PinyinInPreedit=False
      Prediction=False
      KeepCurrentContext=True
      QuickPhraseKey=semicolon
      VAsQuickphrase=True

      [PrevPage]
      0=minus
      1=Up

      [NextPage]
      0=equal
      1=Down

      [PrevCandidate]
      0=Shift+Tab

      [NextCandidate]
      0=Tab

      [CurrentCandidate]
      0=space

      [Fuzzy]
      VE_UE=True
      NG_GN=True
      Inner=True
      InnerShort=True
      PartialFinal=True
    '';

    xdg.configFile."fcitx5/conf/classicui.conf".text = ''
      Vertical Candidate List=True
      WheelForPaging=True
      Font="Sans 10"
      MenuFont="Sans 10"
      TrayFont="Sans Bold 10"
      PreferTextIcon=False
      ShowLayoutNameInIcon=True
      UseInputMethodLanguageToDisplayText=True
      Theme=breeze-opaque-dark-blue
      DarkTheme=default-dark
      UseDarkTheme=True
      UseAccentColor=True
      PerScreenDPI=False
      ForceWaylandDPI=0
      EnableFractionalScale=True
    '';

    xdg.configFile."fcitx5/conf/punctuation.conf".text = ''
      HalfWidthPuncAfterLetterOrNumber=True
      TypePairedPunctuationsTogether=False
      Enabled=True

      [Hotkey]
      0=Control+period
    '';

    xdg.configFile."fcitx5/conf/notifications.conf".text = ''
      [HiddenNotifications]
      0=wayland-diagnose-other
    '';

    xdg.configFile."fcitx5/conf/waylandim.conf".text = ''
      DetectApplication=True
      PreferKeyEvent=True
    '';
  };
}
