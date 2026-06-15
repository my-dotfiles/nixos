{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.hardware.cpu.amd;
in
{
  options.mySystem.hardware.cpu.amd.enable =
    lib.mkEnableOption "AMD CPU support";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.mySystem.hardware.cpu.intel.enable;
        message = "Do not enable both AMD CPU and Intel CPU hardware profiles.";
      }
    ];
    boot.kernelModules = [ "kvm-amd" ];
    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
