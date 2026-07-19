{ config, lib, ... }:

let
  cfg = config.mySystem.core.swap;
in
{
  options.mySystem.core.swap = {
    enable = lib.mkEnableOption "disk-backed swap file";

    device = lib.mkOption {
      type = lib.types.str;
      default = "/home/.swapfile";
      description = "Path to the swap file. The parent filesystem must support swap files.";
    };

    sizeMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 16 * 1024;
      description = "Swap file size in MiB.";
    };

    swappiness = lib.mkOption {
      type = lib.types.ints.between 0 200;
      default = 20;
      description = "Kernel preference for swapping anonymous memory.";
    };

    zramMemoryPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 25;
      description = "Maximum uncompressed zram capacity as a percentage of RAM.";
    };
  };

  config = lib.mkIf cfg.enable {
    swapDevices = [
      {
        inherit (cfg) device;
        priority = 10;
        size = cfg.sizeMiB;
      }
    ];

    boot.kernel.sysctl."vm.swappiness" = cfg.swappiness;

    # Keep a small, fast compressed tier ahead of the NVMe-backed swap file.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = cfg.zramMemoryPercent;
      priority = 100;
    };

    # The service is enabled by default on NixOS, but it does not protect any
    # user workload until the user slices are explicitly opted in.
    systemd.oomd = {
      enable = true;
      enableUserSlices = true;
    };
  };
}
