{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.zed;
in
{
  options.myHome.development.zed.enable = lib.mkEnableOption "Zed editor";

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (lib.hasAttr "zed-editor" pkgs) pkgs.zed-editor;

    xdg.configFile."zed/settings.json".text = ''
      // Zed settings
      {
        "project_panel": {
          "dock": "left"
        },
        "which_key": {
          "enabled": true
        },
        "icon_theme": "Zed (Default)",
        "base_keymap": "Emacs",
        "ui_font_size": 16,
        "buffer_font_size": 15,
        "theme": {
          "mode": "dark",
          "light": "Gruvbox Light",
          "dark": "One Dark"
        },
        "load_direnv": "direct",
        "lsp": {
          "clangd": {
            "binary": {
              "path": "${pkgs.coreutils}/bin/env",
              "arguments": [
                "LC_ALL=C",
                "LANG=C",
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--query-driver=/nix/store/**/bin/clang,/nix/store/**/bin/clang++,/nix/store/**/bin/gcc,/nix/store/**/bin/g++"
              ]
            }
          }
        }
      }
    '';
  };
}
