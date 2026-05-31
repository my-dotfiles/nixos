{ config, lib, ... }:

let
  cfg = config.mySystem.services.proxy;
  proxyEnv = {
    http_proxy = "http://127.0.0.1:7890";
    https_proxy = "http://127.0.0.1:7890";
    HTTP_PROXY = "http://127.0.0.1:7890";
    HTTPS_PROXY = "http://127.0.0.1:7890";
    all_proxy = "socks5h://127.0.0.1:7890";
    ALL_PROXY = "socks5h://127.0.0.1:7890";
    no_proxy = "localhost,127.0.0.1,::1";
    NO_PROXY = "localhost,127.0.0.1,::1";
  };
in
{
  options.mySystem.services.proxy.enable =
    lib.mkEnableOption "local proxy environment for nix-daemon";

  config = lib.mkIf cfg.enable {
    nix.envVars = proxyEnv;
    systemd.services.nix-daemon.environment = proxyEnv;
  };
}
