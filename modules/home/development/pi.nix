{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.pi;
in
{
  options.myHome.development.pi.enable = lib.mkEnableOption "Pi coding agent installed with npm";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs_24
    ];

    home.file.".local/bin/pi-proxy" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        export HTTP_PROXY=http://127.0.0.1:7890
        export HTTPS_PROXY=http://127.0.0.1:7890
        export ALL_PROXY=socks5h://127.0.0.1:7890
        export http_proxy=http://127.0.0.1:7890
        export https_proxy=http://127.0.0.1:7890
        export all_proxy=socks5h://127.0.0.1:7890

        exec pi "$@"
      '';
    };
  };
}
