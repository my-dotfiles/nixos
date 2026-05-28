{ config, lib, ... }:

let
  cfg = config.mySystem.services.proxy;
in
{
  options.mySystem.services.proxy.enable =
    lib.mkEnableOption "local proxy environment for nix-daemon";

  config = lib.mkIf cfg.enable {
    systemd.services.nix-daemon.environment = {
      http_proxy = "http://127.0.0.1:7890";
      https_proxy = "https://127.0.0.1:7890";
      HTTP_PROXY = "http://127.0.0.1:7890";
      HTTPS_PROXY = "http://127.0.0.1:7890";
      all_proxy = "socks5h://127.0.0.1:7890";
      ALL_PROXY = "socks5h://127.0.0.1:7890";
    };
  };
}
