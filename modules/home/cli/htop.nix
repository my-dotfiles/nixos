{ config, lib, ... }:

let
  cfg = config.myHome.cli.htop;
in
{
  options.myHome.cli.htop.enable = lib.mkEnableOption "htop process viewer";

  config = lib.mkIf cfg.enable {
    programs.htop = {
      enable = true;
      settings = {
        color_scheme = 6;
        delay = 15;
        hide_kernel_threads = 1;
        hide_userland_threads = 0;
        highlight_base_name = 1;
        highlight_megabytes = 1;
        highlight_threads = 1;
        shadow_other_users = 0;
        show_cpu_frequency = 1;
        show_cpu_temperature = 1;
        show_program_path = 0;
        tree_view = 0;
      };
    };
  };
}
