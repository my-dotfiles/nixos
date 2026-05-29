{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.yazi;
in
{
  options.myHome.cli.yazi.enable = lib.mkEnableOption "Yazi terminal file manager";

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      extraPackages = with pkgs; [
        fd
        file
        jq
        poppler
        ripgrep
        unzip
      ];
      settings = {
        manager = {
          sort_by = "natural";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "size";
          show_hidden = false;
          show_symlink = true;
        };
        preview = {
          tab_size = 2;
          max_width = 2000;
          max_height = 2000;
        };
      };
    };
  };
}
