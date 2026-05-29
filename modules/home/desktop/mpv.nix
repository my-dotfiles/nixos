{ config, lib, ... }:

let
  cfg = config.myHome.desktop.mpv;
in
{
  options.myHome.desktop.mpv.enable = lib.mkEnableOption "mpv media player";

  config = lib.mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      config = {
        profile = "gpu-hq";
        vo = "gpu-next";
        gpu-api = "vulkan";
        hwdec = "auto-safe";
        save-position-on-quit = "yes";
        osc = "yes";
        osd-bar = "yes";
        sub-auto = "fuzzy";
        slang = "zh,chi,chs,sc,zh-CN,en,eng";
        alang = "jpn,ja,zh,chi,en,eng";
        volume = 80;
      };
    };
  };
}
