{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.hardware.gpu.amd;
in
{
  options.mySystem.hardware.gpu.amd = {
    enable = lib.mkEnableOption "AMD GPU support";

    loadInInitrd = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Load amdgpu early in initrd. Ususally unnecessary unless display init has problems.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.mySystem.hardware.gpu.nvidiaPrime.enable;
        message = "Do not enable both AMD GPU and NVIDIA PRIME GPU profiles";
      }
    ];
    hardware.graphics.enable = true;
    boot.initrd.kernelModules = lib.mkIf cfg.loadInInitrd [ "amdgpu" ];
  };
}
