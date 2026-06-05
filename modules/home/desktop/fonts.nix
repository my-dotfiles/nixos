{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.fonts;
  optionalPkg =
    path:
    let
      value = lib.attrByPath path null pkgs;
    in
    lib.optional (value != null) value;
in
{
  options.myHome.desktop.fonts.enable = lib.mkEnableOption "user fonts and fontconfig";

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages =
      optionalPkg [ "noto-fonts" ]
      ++ optionalPkg [ "noto-fonts-cjk-sans" ]
      ++ optionalPkg [ "noto-fonts-cjk-serif" ]
      ++ optionalPkg [ "noto-fonts-color-emoji" ]
      ++ optionalPkg [ "source-han-sans" ]
      ++ optionalPkg [ "source-han-serif" ]
      ++ optionalPkg [ "sarasa-gothic" ]
      ++ optionalPkg [ "lxgw-wenkai" ]
      ++ optionalPkg [ "wqy_microhei" ]
      ++ optionalPkg [ "wqy_zenhei" ]
      ++ optionalPkg [ "vista-fonts" ]
      ++ optionalPkg [
        "maple-mono"
        "NF-CN"
      ]
      ++ optionalPkg [
        "maple-mono"
        "Normal-CN"
      ]
      ++ optionalPkg [
        "nerd-fonts"
        "jetbrains-mono"
      ]
      ++ optionalPkg [
        "nerd-fonts"
        "fira-code"
      ]
      ++ optionalPkg [
        "nerd-fonts"
        "iosevka"
      ]
      ++ optionalPkg [
        "nerd-fonts"
        "symbols-only"
      ]
      ++ optionalPkg [
        "nerd-fonts"
        "monaspace"
      ];

    xdg.configFile."fontconfig/fonts.conf".text = ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
      <fontconfig>
        <match target="font">
          <edit mode="assign" name="rgba">
            <const>none</const>
          </edit>
        </match>
        <match target="font">
          <edit mode="assign" name="hinting">
            <bool>true</bool>
          </edit>
        </match>
        <match target="font">
          <edit mode="assign" name="hintstyle">
            <const>hintslight</const>
          </edit>
        </match>
        <match target="font">
          <edit mode="assign" name="antialias">
            <bool>true</bool>
          </edit>
        </match>
      </fontconfig>
    '';

    xdg.configFile."fontconfig/conf.d/50-user-defaults.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <alias>
          <family>sans-serif</family>
          <prefer>
            <family>Noto Sans CJK SC</family>
            <family>Noto Sans</family>
            <family>Source Han Sans SC</family>
            <family>Sarasa Gothic SC</family>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
        <alias>
          <family>serif</family>
          <prefer>
            <family>Noto Serif CJK SC</family>
            <family>Noto Serif</family>
            <family>Source Han Serif SC</family>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
        <alias>
          <family>monospace</family>
          <prefer>
            <family>Monospace Neon</family>
            <family>Maple Mono NF CN</family>
            <family>JetBrainsMono Nerd Font</family>
            <family>Sarasa Mono SC</family>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
        <alias>
          <family>emoji</family>
          <prefer>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
      </fontconfig>
    '';

    xdg.configFile."fontconfig/conf.d/60-terminal-cjk.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="family" qual="any">
            <string>JetBrainsMono Nerd Font</string>
          </test>
          <edit name="family" mode="append" binding="strong">
            <string>Sarasa Mono SC</string>
          </edit>
        </match>
        <match target="pattern">
          <test name="family" qual="any">
            <string>Iosevka Nerd Font Mono</string>
          </test>
          <edit name="family" mode="append" binding="strong">
            <string>Maple Mono NF CN</string>
          </edit>
        </match>
      </fontconfig>
    '';
  };
}
