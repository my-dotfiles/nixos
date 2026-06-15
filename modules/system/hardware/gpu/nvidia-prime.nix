{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.hardware.gpu.nvidiaPrime;
in
{
  options.mySystem.hardware.gpu.nvidiaPrime =
    {
      enable = lib.mkEnableOption "NVIDIA PRIME graphics support";

      integratedGpu = lib.mkOption {
        type = lib.types.enum [ "intel" "amd" ];
        default = "intel";
        description = "The integrated GPU used together with NVIDIA dGPU.";
      };
      intelBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:0:2:0";
      };

      amdgpuBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:5:0:0";
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:1:0:0";
      };

      open = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use Nvidia open kernel modules when supported.";
      };
      powerManagement = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        finegrained = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.mySystem.hardware.gpu.amd.enable;
        message = "Do not enable both NVIDIA PRIME and AMD GPU hardware profiles";
      }
      {
        assertion = cfg.nvidiaBusId != null;
        message = "NVIDIA PRIME requires nvidiaBusId.";
      }
      {
        assertion =
          if cfg.integratedGpu == "intel"
          then cfg.intelBusId != null
          else cfg.amdgpuBusId != null;
        message = "NVIDIA PRIME requires the integrated GPU bus ID.";
      }
    ];
    hardware.graphics.enable = true;
    services.xserver.videoDrivers =
      if cfg.integratedGpu == "intel"
      then [ "modesetting" "nvidia" ]
      else [ "amdgpu" "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;

      open = cfg.open;
      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;

      powerManagement = {
        enable = cfg.powerManagement.enable;
        finegrained = cfg.powerManagement.finegrained;
      };

      prime =
        {
          nvidiaBusId = cfg.nvidiaBusId;

          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
        }
        // lib.optionalAttrs (cfg.integratedGpu == "intel") {
          intelBusId = cfg.intelBusId;
        }
        // lib.optionalAttrs (cfg.integratedGpu == "amd") {
          amdgpuBusId = cfg.amdgpuBusId;
        };
    };
  };
}
