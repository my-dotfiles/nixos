{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.steam;
in
{
  options.mySystem.desktop.steam.enable = lib.mkEnableOption "Steam gaming platform";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.protontricks ];

    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraArgs = "-system-composer";
        # Steam and every game it launches inherit PRIME offload. Sway remains
        # on Intel, while OpenGL and Vulkan games default to the NVIDIA GPU.
        extraEnv = {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          __VK_LAYER_NV_optimus = "NVIDIA_only";
        };
      };
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.gamemode.enable = true;
  };
}
