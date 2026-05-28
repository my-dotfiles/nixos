{ ... }:

{
  xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard {
        xkb {
          layout "us"
        }
      }
    }
    spawn-at-startup "fcitx5"
    spawn-at-startup "noctalia-shell"
    binds {
      Mod+Return { spawn "ghostty"; }
      Mod+D { spawn "fuzzel"; }
      Mod+Q { close-window; }
    }
  '';
}
