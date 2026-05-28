{ config, lib, ... }:

let
  cfg = config.myHome.development.editor;
in
{
  options.myHome.development.editor.enable = lib.mkEnableOption "Helix editor";

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = {
        theme = "gruvbox_dark_hard";
        editor = {
          line-number = "relative";
          cursorline = true;
          color-modes = true;
          true-color = true;
          bufferline = "multiple";
          popup-border = "all";
          auto-completion = true;
          auto-format = false;
          completion-trigger-len = 1;
          end-of-line-diagnostics = "warning";
          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };
          statusline = {
            left = [
              "mode"
              "spinner"
              "file-name"
              "read-only-indicator"
              "file-modification-indicator"
            ];
            center = [ "diagnostics" ];
            right = [
              "selections"
              "position"
              "file-encoding"
              "file-type"
            ];
          };
          indent-guides = {
            render = true;
            character = "|";
          };
          soft-wrap = {
            enable = false;
            max-wrap = 120;
            wrap-indicator = ">";
          };
        };
        keys = {
          normal = {
            H = "goto_previous_buffer";
            L = "goto_next_buffer";
          };
          insert.j.k = "normal_mode";
        };
      };
      languages.language = [
        {
          name = "markdown";
          soft-wrap.enable = true;
        }
        {
          name = "nix";
          auto-format = true;
        }
        {
          name = "python";
          auto-format = false;
        }
        {
          name = "java";
          auto-format = false;
        }
        {
          name = "rust";
          auto-format = false;
        }
      ];
    };
  };
}
