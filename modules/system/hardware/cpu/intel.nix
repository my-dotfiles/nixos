{ config, lib, ... }:

let
  cfg = config.mySystem.hardware.cpu.intel;

in
{
  options.mySystem.hardware.cpu.intel.enable =
    lib.mkEnableOption "Intel CPU support";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.mySystem.hardware.cpu.amd.enable;
        message = "Do not enable both Intel CPU and AMD CPU hardware profiles.";
      }
    ];

    boot.kernelModules = [ "kvm-intel" ];

    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
