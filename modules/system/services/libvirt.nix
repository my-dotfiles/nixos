{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.services.libvirt;
in
{
  options.mySystem.services.libvirt.enable = lib.mkEnableOption "libvirt virtual machine management";

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    users.users.yurikon.extraGroups = [ "libvirtd" ];
  };
}
