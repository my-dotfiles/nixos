{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.mpv;
in
{
  options.myHome.desktop.mpv.enable = lib.mkEnableOption "mpv media player";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg-full
      yt-dlp

      gst_all_1.gst-libav
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
    ];

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
