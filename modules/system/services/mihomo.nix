{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.services.mihomo;
  configFile = "/etc/mihomo/config.yaml";
  controller = "http://127.0.0.1:9090";

  baseConfig = pkgs.writeText "mihomo-base-config.json" (
    builtins.toJSON {
      mixed-port = 7890;
      allow-lan = false;
      mode = "rule";
      log-level = "info";
      ipv6 = true;
      geodata-mode = true;
      external-controller = "127.0.0.1:9090";
      profile = {
        store-selected = true;
        store-fake-ip = true;
      };
      tun = {
        enable = true;
        stack = "gvisor";
        auto-route = true;
        auto-detect-interface = true;
        dns-hijack = [ "any:53" ];
      };
      dns = {
        enable = true;
        ipv6 = true;
        enhanced-mode = "fake-ip";
        fake-ip-range = "198.18.0.1/16";
        default-nameserver = [
          "223.5.5.5"
          "1.1.1.1"
        ];
        nameserver = [
          "https://dns.alidns.com/dns-query"
          "https://1.1.1.1/dns-query"
        ];
        proxy-server-nameserver = [ "https://dns.alidns.com/dns-query" ];
      };
      proxies = [ ];
      proxy-groups = [
        {
          name = "PROXY";
          type = "select";
          proxies = [ "DIRECT" ];
        }
      ];
      rules = [ "MATCH,DIRECT" ];
    }
  );

  subscriptionConfig = pkgs.writeText "mihomo-subscription-config.json" (
    builtins.toJSON {
      mixed-port = 7890;
      allow-lan = false;
      mode = "rule";
      log-level = "info";
      ipv6 = true;
      geodata-mode = true;
      external-controller = "127.0.0.1:9090";
      profile = {
        store-selected = true;
        store-fake-ip = true;
      };
      tun = {
        enable = true;
        stack = "gvisor";
        auto-route = true;
        auto-detect-interface = true;
        dns-hijack = [ "any:53" ];
      };
      dns = {
        enable = true;
        ipv6 = true;
        enhanced-mode = "fake-ip";
        fake-ip-range = "198.18.0.1/16";
        default-nameserver = [
          "223.5.5.5"
          "1.1.1.1"
        ];
        nameserver = [
          "https://dns.alidns.com/dns-query"
          "https://1.1.1.1/dns-query"
        ];
        proxy-server-nameserver = [ "https://dns.alidns.com/dns-query" ];
      };
      proxy-providers.subscription = {
        type = "http";
        url = "SUBSCRIPTION_URL";
        path = "./providers/subscription.yaml";
        interval = 3600;
        health-check = {
          enable = true;
          url = "http://www.gstatic.com/generate_204";
          interval = 300;
        };
      };
      proxy-groups = [
        {
          name = "PROXY";
          type = "select";
          proxies = [
            "AUTO"
            "DIRECT"
          ];
          use = [ "subscription" ];
        }
        {
          name = "AUTO";
          type = "url-test";
          use = [ "subscription" ];
          url = "http://www.gstatic.com/generate_204";
          interval = 300;
          tolerance = 50;
        }
      ];
      rules = [
        "DOMAIN-SUFFIX,lan,DIRECT"
        "DOMAIN-SUFFIX,local,DIRECT"
        "DOMAIN-SUFFIX,codeberg.org,DIRECT"
        "GEOSITE,private,DIRECT"
        "GEOSITE,CN,DIRECT"
        "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve"
        "IP-CIDR,100.64.0.0/10,DIRECT,no-resolve"
        "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve"
        "IP-CIDR,169.254.0.0/16,DIRECT,no-resolve"
        "IP-CIDR,172.16.0.0/12,DIRECT,no-resolve"
        "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve"
        "IP-CIDR6,fc00::/7,DIRECT,no-resolve"
        "IP-CIDR6,fe80::/10,DIRECT,no-resolve"
        "GEOIP,CN,DIRECT,no-resolve"
        "MATCH,PROXY"
      ];
    }
  );

  mihomoSubscription = pkgs.writeShellApplication {
    name = "mihomo-subscription";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      mihomo
      systemd
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0"
      fi

      printf 'Subscription URL: ' >&2
      IFS= read -r subscription_url
      case "$subscription_url" in
        http://*|https://*) ;;
        *)
          echo "The subscription URL must start with http:// or https://" >&2
          exit 2
          ;;
      esac

      tmp_file="$(mktemp /etc/mihomo/config.yaml.XXXXXX)"
      validation_dir="$(mktemp -d /tmp/mihomo-validate.XXXXXX)"
      trap 'rm -f -- "$tmp_file"; rm -rf -- "$validation_dir"' EXIT
      jq --arg url "$subscription_url" \
        '."proxy-providers".subscription.url = $url' \
        ${subscriptionConfig} > "$tmp_file"
      chmod 600 "$tmp_file"

      ln -s ${pkgs.v2ray-geoip}/share/v2ray/geoip.dat "$validation_dir/GeoIP.dat"
      ln -s ${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat \
        "$validation_dir/GeoSite.dat"
      mihomo -t -d "$validation_dir" -f "$tmp_file"
      mv -f -- "$tmp_file" ${configFile}
      rm -rf -- "$validation_dir"
      trap - EXIT
      systemctl restart mihomo.service
      echo "Subscription installed. MetaCubeXD: ${controller}/ui/"
    '';
  };

  mihomoCtl = pkgs.writeShellApplication {
    name = "mihomoctl";
    runtimeInputs = with pkgs; [
      curl
      jq
      systemd
      xdg-utils
    ];
    text = ''
      set -euo pipefail
      api=${lib.escapeShellArg controller}

      request() {
        curl --fail --silent --show-error "$@"
      }

      usage() {
        cat <<'EOF'
      Usage: mihomoctl COMMAND [ARG]

        status                    show service and runtime state
        mode rule|global|direct   switch routing mode
        tun on|off                enable or disable TUN at runtime
        update                    refresh the subscription immediately
        nodes                     list nodes in the PROXY group
        select NODE               select a node in the PROXY group
        ui                        open MetaCubeXD
        logs                      follow service logs
        restart                   restart the Mihomo service
        subscription              securely replace the subscription URL
      EOF
      }

      case "''${1:-}" in
        status)
          systemctl --no-pager --full status mihomo.service || true
          echo
          request "$api/configs" | jq '{mode, tun: .tun.enable, mixed_port: .["mixed-port"]}'
          ;;
        mode)
          case "''${2:-}" in
            rule|global|direct)
              request -X PATCH -H 'Content-Type: application/json' \
                -d "$(jq -cn --arg mode "$2" '{mode: $mode}')" "$api/configs"
              echo "Mode: $2"
              ;;
            *) usage; exit 2 ;;
          esac
          ;;
        tun)
          case "''${2:-}" in
            on) enabled=true ;;
            off) enabled=false ;;
            *) usage; exit 2 ;;
          esac
          request -X PATCH -H 'Content-Type: application/json' \
            -d "$(jq -cn --argjson enabled "$enabled" '{tun: {enable: $enabled}}')" \
            "$api/configs"
          echo "TUN: $2"
          ;;
        update)
          request -X PUT "$api/providers/proxies/subscription"
          echo "Subscription updated"
          ;;
        nodes)
          request "$api/proxies/PROXY" | jq -r '.all[]'
          ;;
        select)
          [ -n "''${2:-}" ] || { usage; exit 2; }
          request -X PUT -H 'Content-Type: application/json' \
            -d "$(jq -cn --arg name "$2" '{name: $name}')" "$api/proxies/PROXY"
          echo "PROXY: $2"
          ;;
        ui)
          exec xdg-open "$api/ui/"
          ;;
        logs)
          exec journalctl -u mihomo.service -f
          ;;
        restart)
          exec sudo systemctl restart mihomo.service
          ;;
        subscription)
          exec ${lib.getExe mihomoSubscription}
          ;;
        *) usage; exit 2 ;;
      esac
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "metacubexd";
    desktopName = "MetaCubeXD";
    genericName = "Mihomo proxy control panel";
    comment = "Open the local Mihomo control panel";
    icon = "network-vpn";
    exec = "${lib.getExe mihomoCtl} ui";
    categories = [ "Network" ];
    keywords = [
      "Mihomo"
      "Clash"
      "Proxy"
      "VPN"
    ];
  };
in
{
  options.mySystem.services.mihomo.enable =
    lib.mkEnableOption "system-level Mihomo proxy with MetaCubeXD";

  config = lib.mkIf cfg.enable {
    services.mihomo = {
      enable = true;
      inherit configFile;
      webui = pkgs.metacubexd;
      tunMode = true;
      processesInfo = true;
    };

    systemd.services.mihomo.preStart = ''
      ln -sfn ${pkgs.v2ray-geoip}/share/v2ray/geoip.dat /var/lib/private/mihomo/GeoIP.dat
      ln -sfn ${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat /var/lib/private/mihomo/GeoSite.dat
    '';
    systemd.services.mihomo.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "3s";
    };

    system.activationScripts.mihomoConfig = {
      deps = [ "etc" ];
      text = ''
        install -d -m 700 /etc/mihomo
        if [ ! -e ${configFile} ]; then
          install -m 600 ${baseConfig} ${configFile}
        fi
      '';
    };

    environment.systemPackages = [
      desktopItem
      mihomoCtl
      mihomoSubscription
    ];
  };
}
