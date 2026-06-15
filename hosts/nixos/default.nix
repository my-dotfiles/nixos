{ ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../../modules/system/hardware
    ../../modules/system/profiles/workstation.nix
  ];

  networking.hostName = "nixos";

  mySystem.hardware = {
    cpu.intel.enable = true;

    gpu.nvidiaPrime = {
      enable = true;
      integratedGpu = "intel";
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  system.stateVersion = "26.05";
}
