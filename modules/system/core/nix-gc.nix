{ config, lib, ... }:

let
  cfg = config.mySystem.core.nixGc;
in
{
  options.mySystem.core.nixGc.enable =
    lib.mkEnableOption "weekly Nix garbage collection keeping the latest 15 NixOS generations";

  config = lib.mkIf cfg.enable {
    # The built-in nix.gc options only support age-based retention. Prune the
    # system profile explicitly so retention can be based on generation count.
    nix.gc.automatic = false;

    systemd.services.nix-generation-prune = {
      description = "Prune old NixOS generations and collect garbage";

      serviceConfig.Type = "oneshot";

      script = ''
        ${config.nix.package}/bin/nix-env \
          --profile /nix/var/nix/profiles/system \
          --delete-generations +15
        ${config.nix.package}/bin/nix-collect-garbage
      '';
    };

    systemd.timers.nix-generation-prune = {
      description = "Weekly NixOS generation pruning";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
