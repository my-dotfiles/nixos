{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.sway;
  appRunner = "${lib.getExe' pkgs.systemd "systemd-run"} --user --scope --slice=app.slice --quiet --collect --";
  terminal = "${appRunner} ${lib.getExe pkgs.alacritty}";
  fuzzel = lib.getExe pkgs.fuzzel;
  menu = "${fuzzel} --launch-prefix='${appRunner}'";
  primaryOutput = "DP-1";
  laptopOutput = "eDP-1";
  flclashAppId = "com.follow.clash";
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
  wallpaper = "${config.home.homeDirectory}/Pictures/图片/walls/nord/a_cat_walking_on_a_hill.png";
  swaymsg = lib.getExe' pkgs.sway "swaymsg";
  wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
  wlPaste = lib.getExe' pkgs.wl-clipboard "wl-paste";
  cliphist = lib.getExe pkgs.cliphist;
  notifySend = lib.getExe pkgs.libnotify;
  bluetoothctl = lib.getExe' pkgs.bluez "bluetoothctl";
  powerMenu = pkgs.writeShellScriptBin "sway-power-menu" ''
    choice="$(${lib.getExe pkgs.fuzzel} --dmenu --prompt "Power: " <<'EOF'
    Lock
    Suspend
    Log out
    Reboot
    Power off
    EOF
    )" || exit 0

    case "$choice" in
      Lock) exec lock-screen ;;
      Suspend) exec ${lib.getExe' pkgs.systemd "systemctl"} suspend ;;
      "Log out") exec ${swaymsg} exit ;;
      Reboot) exec ${lib.getExe' pkgs.systemd "systemctl"} reboot ;;
      "Power off") exec ${lib.getExe' pkgs.systemd "systemctl"} poweroff ;;
    esac
  '';
  swayConfig =
    builtins.replaceStrings
      [
        "@terminal@"
        "@menu@"
        "@home@"
      ]
      [
        terminal
        menu
        config.home.homeDirectory
      ]
      (builtins.readFile ./sway/config);
  setWallpaper = pkgs.writeShellScript "set-sway-wallpaper" ''
    if [ -f "${wallpaper}" ]; then
      exec ${lib.getExe pkgs.swaybg} -i "${wallpaper}" -m fill
    fi
  '';
  flclashGui = pkgs.writeShellScriptBin "flclash-gui" ''
    has_window() {
      ${swaymsg} -t get_tree \
        | ${lib.getExe pkgs.jq} -e '.. | objects | select(.app_id? == "${flclashAppId}")' >/dev/null
    }

    if ${pkgs.procps}/bin/pgrep -x FlClash >/dev/null; then
      if has_window; then
        ${swaymsg} '[app_id="${flclashAppId}"] scratchpad show, focus'
        exit 0
      fi

      ${pkgs.procps}/bin/pkill -x FlClash
      sleep 1
    fi

    exec ${lib.getExe' pkgs.flclash "FlClash"} "$@"
  '';
  closeWindow = pkgs.writeShellScriptBin "close-sway-window" ''
    app_id="$(${swaymsg} -t get_tree \
      | ${lib.getExe pkgs.jq} -r '.. | objects | select(.focused? == true) | .app_id // empty' \
      | ${pkgs.coreutils}/bin/head -n1)"

    if [ "$app_id" = "${flclashAppId}" ]; then
      exec ${swaymsg} move scratchpad
    fi

    exec ${swaymsg} kill
  '';
  screenshot =
    mode:
    pkgs.writeShellScriptBin "screenshot-${mode}" ''
      set -eu

      dir="${screenshotDir}"
      ${pkgs.coreutils}/bin/mkdir -p "$dir"
      file="$dir/Screenshot from $(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H-%M-%S').png"

      case "${mode}" in
        area)
          geometry="$(${lib.getExe pkgs.slurp})"
          [ -n "$geometry" ]
          ${lib.getExe pkgs.grim} -g "$geometry" "$file"
          ;;
        edit)
          geometry="$(${lib.getExe pkgs.slurp})"
          [ -n "$geometry" ]
          ${lib.getExe pkgs.grim} -g "$geometry" - | ${lib.getExe pkgs.swappy} -f -
          exit 0
          ;;
        screen)
          ${lib.getExe pkgs.grim} "$file"
          ;;
        window)
          geometry="$(${swaymsg} -t get_tree \
            | ${lib.getExe pkgs.jq} -r '.. | objects | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' \
            | ${pkgs.coreutils}/bin/head -n1)"
          [ -n "$geometry" ]
          ${lib.getExe pkgs.grim} -g "$geometry" "$file"
          ;;
      esac

      ${wlCopy} < "$file"
    '';
  clipboardMenu = pkgs.writeShellScriptBin "clipboard-menu" ''
    set -eu

    pins_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/cliphist-pins"
    menu_file="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f -- "$menu_file"' EXIT
    ${pkgs.coreutils}/bin/mkdir -p "$pins_dir"

    for pin in "$pins_dir"/*; do
      [ -f "$pin" ] || continue
      preview="$(${pkgs.coreutils}/bin/tr '\n\t' '  ' < "$pin" | ${pkgs.coreutils}/bin/cut -c1-100)"
      ${pkgs.coreutils}/bin/printf 'P:%s\t★ %s\n' "$(${pkgs.coreutils}/bin/basename "$pin")" "$preview" >> "$menu_file"
    done

    while IFS=$'\t' read -r id preview; do
      [ -n "$id" ] || continue
      ${pkgs.coreutils}/bin/printf 'H:%s\t%s\n' "$id" "$preview" >> "$menu_file"
    done < <(${cliphist} list)

    selection="$(${fuzzel} --dmenu --prompt 'Clipboard: ' --with-nth=2 --accept-nth=1 --only-match < "$menu_file")" || exit 0

    case "$selection" in
      P:*)
        pin="''${selection#P:}"
        case "$pin" in
          ""|*[!0-9a-f]*) exit 1 ;;
        esac
        ${wlCopy} < "$pins_dir/$pin"
        ;;
      H:*)
        id="''${selection#H:}"
        ${pkgs.coreutils}/bin/printf '%s' "$id" | ${cliphist} decode | ${wlCopy}
        ;;
    esac
  '';
  clipboardPin = pkgs.writeShellScriptBin "clipboard-pin" ''
    set -eu

    pins_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/cliphist-pins"
    item="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f -- "$item"' EXIT
    ${pkgs.coreutils}/bin/mkdir -p "$pins_dir"

    if ! ${wlPaste} --type text > "$item" || [ ! -s "$item" ]; then
      ${notifySend} "Clipboard" "Only non-empty text can be pinned"
      exit 1
    fi

    hash="$(${pkgs.coreutils}/bin/sha256sum "$item")"
    hash="''${hash%% *}"
    ${pkgs.coreutils}/bin/install -m 600 "$item" "$pins_dir/$hash"
    ${notifySend} "Clipboard" "Pinned current text"
  '';
  clipboardUnpin = pkgs.writeShellScriptBin "clipboard-unpin" ''
    set -eu

    pins_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/cliphist-pins"
    menu_file="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f -- "$menu_file"' EXIT
    ${pkgs.coreutils}/bin/mkdir -p "$pins_dir"

    for pin in "$pins_dir"/*; do
      [ -f "$pin" ] || continue
      preview="$(${pkgs.coreutils}/bin/tr '\n\t' '  ' < "$pin" | ${pkgs.coreutils}/bin/cut -c1-100)"
      ${pkgs.coreutils}/bin/printf '%s\t%s\n' "$(${pkgs.coreutils}/bin/basename "$pin")" "$preview" >> "$menu_file"
    done

    pin="$(${fuzzel} --dmenu --prompt 'Unpin: ' --with-nth=2 --accept-nth=1 --only-match < "$menu_file")" || exit 0
    case "$pin" in
      ""|*[!0-9a-f]*) exit 1 ;;
    esac
    ${pkgs.coreutils}/bin/rm -f -- "$pins_dir/$pin"
    ${notifySend} "Clipboard" "Removed pinned text"
  '';
  bluetoothMenu = pkgs.writeShellScriptBin "sway-bluetooth-menu" ''
    set -eu

    menu_file="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f -- "$menu_file"' EXIT

    if ${bluetoothctl} show | ${pkgs.gnugrep}/bin/grep -q 'Powered: yes'; then
      ${pkgs.coreutils}/bin/printf 'power-off\t󰂲  Turn Bluetooth off\n' >> "$menu_file"
    else
      ${pkgs.coreutils}/bin/printf 'power-on\t󰂯  Turn Bluetooth on\n' >> "$menu_file"
    fi

    while read -r _ address name; do
      [ -n "$address" ] || continue
      info="$(${bluetoothctl} info "$address" 2>/dev/null || true)"
      ${pkgs.gnugrep}/bin/grep -q 'Paired: yes' <<< "$info" || continue

      if ${pkgs.gnugrep}/bin/grep -q 'Connected: yes' <<< "$info"; then
        status="󰂱"
      else
        status="󰂯"
      fi
      ${pkgs.coreutils}/bin/printf 'device:%s\t%s  %s\n' "$address" "$status" "$name" >> "$menu_file"
    done < <(${bluetoothctl} devices)

    ${pkgs.coreutils}/bin/printf 'advanced\t󰒓  Device settings…\n' >> "$menu_file"
    selection="$(${fuzzel} --dmenu --prompt 'Bluetooth: ' --with-nth=2 --accept-nth=1 --only-match < "$menu_file")" || exit 0

    case "$selection" in
      power-on) ${bluetoothctl} power on ;;
      power-off) ${bluetoothctl} power off ;;
      advanced) exec ${lib.getExe' pkgs.blueman "blueman-manager"} ;;
      device:*)
        address="''${selection#device:}"
        if ${bluetoothctl} info "$address" | ${pkgs.gnugrep}/bin/grep -q 'Connected: yes'; then
          ${bluetoothctl} disconnect "$address"
        else
          ${bluetoothctl} connect "$address"
        fi
        ;;
    esac
  '';
  swayOsd = pkgs.writeShellScriptBin "sway-osd" ''
    set -eu

    case "''${1:-}" in
      volume-up) ${lib.getExe' pkgs.wireplumber "wpctl"} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
      volume-down) ${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
      volume-mute) ${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      brightness-up) ${lib.getExe pkgs.brightnessctl} set 5%+ ;;
      brightness-down) ${lib.getExe pkgs.brightnessctl} set 5%- ;;
      *) exit 2 ;;
    esac

    case "$1" in
      volume-*)
        ${lib.getExe' pkgs.wireplumber "wpctl"} get-volume @DEFAULT_AUDIO_SINK@ \
          | ${pkgs.gawk}/bin/awk '{ if ($0 ~ /MUTED/) print "0 muted"; else printf "%.0f\n", $2 * 100 }' \
          > "''${XDG_RUNTIME_DIR}/wob.sock"
        ;;
      brightness-*)
        ${lib.getExe pkgs.brightnessctl} -m \
          | ${pkgs.gawk}/bin/awk -F, '{ sub(/%/, "", $4); print $4 }' \
          > "''${XDG_RUNTIME_DIR}/wob.sock"
        ;;
    esac
  '';
  cliphistWatch = pkgs.writeShellScript "cliphist-watch" ''
    exec ${wlPaste} --watch ${cliphist} store
  '';
in
{
  options.myHome.desktop.sway.enable = lib.mkEnableOption "Sway compositor user configuration";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      closeWindow
      bluetoothMenu
      blueman
      clipboardMenu
      clipboardPin
      clipboardUnpin
      pkgs.cliphist
      flclashGui
      pkgs.fuzzel
      jq
      libnotify
      networkmanagerapplet
      networkmanager_dmenu
      pavucontrol
      polkit_gnome
      powerMenu
      (screenshot "area")
      (screenshot "edit")
      (screenshot "screen")
      (screenshot "window")
      swaybg
      swayOsd
      wob
      wdisplays
      xdg-utils
    ];

    xdg.dataFile."applications/flclash.desktop".text = ''
      [Desktop Entry]
      Categories=Network
      Exec=flclash-gui %U
      GenericName=FlClash
      Icon=flclash
      Keywords=FlClash;Clash;ClashMeta;Proxy;
      Name=FlClash
      Type=Application
      Version=1.5
    '';

    services.mako = {
      enable = true;
      package = pkgs.mako;
      settings = {
        anchor = "top-right";
        layer = "overlay";
        font = "Sans 10";
        width = 420;
        height = 160;
        margin = "12";
        padding = "10";
        border-size = 2;
        border-radius = 6;
        background-color = "#111318e6";
        text-color = "#e6edf3ff";
        border-color = "#7fc8ffff";
        progress-color = "over #7fc8ff66";
        default-timeout = 6000;
        ignore-timeout = false;
        icons = true;
        markup = true;
        actions = true;
        max-visible = 5;
        sort = "-time";
        on-button-left = "dismiss";
        on-button-right = "dismiss-all";
        "urgency=high" = {
          border-color = "#ff7f7fff";
          default-timeout = 0;
          ignore-timeout = true;
        };
      };
    };

    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
      tray = "auto";
    };

    xsession.preferStatusNotifierItems = true;

    xdg.configFile."networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${fuzzel}
      active_chars = ●
      compact = True
      wifi_chars = ▂▄▆█
      format = {name}  {sec}  {bars}
      list_saved = False
      prompt = Network

      [editor]
      gui_if_available = True
      gui = nm-connection-editor

      [nmdm]
      rescan_delay = 3
      show_notifications = True
    '';

    xdg.configFile."wob/wob.ini".text = ''
      timeout = 900
      max = 100
      width = 320
      height = 24
      border_size = 2
      bar_padding = 3
      anchor = bottom center
      margin = 64
      border_color = 7fc8ffff
      background_color = 111318e6
      bar_color = 7fc8ffff

      [style.muted]
      border_color = ff7f7fff
      bar_color = ff7f7fff
    '';

    # Prefer the external monitor when it is connected. When DP-1 disappears,
    # Kanshi restores the laptop panel automatically.
    services.kanshi = {
      enable = true;
      systemdTarget = "sway-session.target";
      settings = [
        {
          profile = {
            name = "docked";
            outputs = [
              {
                criteria = primaryOutput;
                status = "enable";
                mode = "2560x1440@165Hz";
                position = "0,0";
                scale = 1.25;
              }
              {
                criteria = laptopOutput;
                status = "disable";
              }
            ];
          };
        }
        {
          profile = {
            name = "mobile";
            outputs = [
              {
                criteria = laptopOutput;
                status = "enable";
                mode = "2560x1600@120Hz";
                position = "0,0";
                scale = 1.6;
              }
            ];
          };
        }
      ];
    };

    # 使用 Waybar 替代 swaybar。Waybar 的 tray 模块更接近传统桌面托盘行为，
    # FLClash、Steam 这类应用的右键菜单优先交给它处理。
    programs.workstyle = {
      enable = true;
      systemd = {
        enable = true;
        target = "sway-session.target";
      };
      settings = {
        # workstyle 会根据窗口 app_id/class 动态重命名 workspace，Waybar 直接显示结果。
        # 使用短字符而不是大图标，避免状态栏变宽或依赖特定图标字体。
        dolphin = "F";
        "org.kde.dolphin" = "F";
        firefox = "W";
        "org.mozilla.firefox" = "W";
        qutebrowser = "W";
        emacs = "E";
        "emacsclient" = "E";
        code = "E";
        Code = "E";
        thunar = "F";
        "org.gnome.Nautilus" = "F";
        thunderbird = "M";
        steam = "S";
        Steam = "S";
        "com.follow.clash" = "C";
        FlClash = "C";
        Alacritty = "T";
        alacritty = "T";
        "org.pwmt.zathura" = "D";
        zotero = "Z";
        other = {
          fallback_icon = "·";
          deduplicate_icons = true;
          separator = " ";
        };
      };
    };

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        targets = [ "sway-session.target" ];
      };
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        spacing = 6;

        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [ "sway/window" ];
        modules-right = [
          "idle_inhibitor"
          "tray"
          "network"
          "bluetooth"
          "pulseaudio"
          "memory"
          "battery"
          "clock"
          "custom/power"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
          # Workstyle 会把 workspace 名称改为「编号: 窗口字符」，这里显示完整名称。
          format = "{name}";
        };
        tray = {
          icon-size = 14;
          spacing = 6;
        };
        network = {
          interval = 10;
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "networkmanager_dmenu";
          on-click-right = "nm-connection-editor";
        };
        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-connected = "󰂱 {num_connections}";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          on-click = "sway-bluetooth-menu";
          on-click-right = "blueman-manager";
        };
        pulseaudio = {
          format = "V {volume}%";
          format-muted = "V mute";
          scroll-step = 5;
          on-click = "pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          tooltip-format = "{desc}";
        };
        memory = {
          interval = 10;
          states = {
            warning = 75;
            critical = 90;
          };
          format = "M {percentage}%";
          tooltip-format = "Memory: {used:0.1f} GiB / {total:0.1f} GiB\nSwap: {swapUsed:0.1f} GiB / {swapTotal:0.1f} GiB";
          on-click = "${terminal} -e ${lib.getExe pkgs.btop}";
        };
        battery = {
          interval = 10;
          states = {
            warning = 20;
            critical = 7;
          };
          format = "P {capacity}%";
          format-charging = "P+ {capacity}%";
          format-plugged = "AC {capacity}%";
          tooltip-format = "{timeTo} · {power} W";
        };
        clock = {
          interval = 60;
          format = "{:%m-%d %H:%M}";
          tooltip-format = "{:%Y-%m-%d %A}";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "Awake";
            deactivated = "Idle";
          };
          tooltip = true;
        };
        "sway/window" = {
          format = "{title}";
          max-length = 80;
          rewrite = {
            "(.*) — Mozilla Firefox" = "$1";
            "(.*) - Visual Studio Code" = "$1";
          };
        };
        "custom/power" = {
          format = "Power";
          tooltip = false;
          on-click = "sway-power-menu";
        };
      };
      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "Maple Mono NF CN", monospace;
          font-size: 10pt;
          min-height: 0;
        }

        window#waybar {
          background: #111318;
          color: #e6edf3;
        }

        #workspaces button {
          color: #8b949e;
          padding: 0 5px;
        }

        #workspaces button.focused,
        #workspaces button.visible {
          background: #7fc8ff;
          color: #111318;
        }

        #mode,
        #idle_inhibitor,
        #tray,
        #network,
        #bluetooth,
        #pulseaudio,
        #memory,
        #battery,
        #clock {
          padding: 0 6px;
        }

        #battery.warning,
        #memory.warning {
          color: #ffd37f;
        }

        #battery.critical {
          color: #ff7f7f;
        }

        #memory.critical {
          background: #ff7f7f;
          color: #111318;
        }

        #custom-power {
          background: #7fc8ff;
          color: #111318;
          padding: 0 8px;
        }
      '';
    };

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland,x11";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_DESKTOP = "sway";
    };

    systemd.user.services.polkit-gnome-authentication-agent = {
      Unit = {
        Description = "PolicyKit authentication agent";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.services.fcitx5 = {
      Unit = {
        Description = "Fcitx5 input method daemon";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "/run/current-system/sw/bin/fcitx5";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.services.swaybg = {
      Unit = {
        Description = "Sway wallpaper";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${setWallpaper}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.services.cliphist = {
      Unit = {
        Description = "Wayland clipboard history";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Service = {
        ExecStart = "${cliphistWatch}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.sockets.wob = {
      Unit = {
        Description = "Wob overlay socket";
        PartOf = [ "sway-session.target" ];
      };
      Socket = {
        ListenFIFO = "%t/wob.sock";
        SocketMode = "0600";
        RemoveOnStop = true;
        FlushPending = true;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.services.wob = {
      Unit = {
        Description = "Wayland overlay bar";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe pkgs.wob;
        StandardInput = "socket";
        StandardOutput = "journal";
      };
    };

    systemd.user.services.udiskie.Service = {
      Restart = "on-failure";
      RestartSec = 2;
    };

    wayland.windowManager.sway = {
      enable = true;
      systemd = {
        enable = true;
        # Keep D-Bus activated applications in sync with the Sway session,
        # including the input method and native Wayland preferences.
        variables = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "SWAYSOCK"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_DESKTOP"
          "XDG_SESSION_TYPE"
          "NIXOS_OZONE_WL"
          "MOZ_ENABLE_WAYLAND"
          "QT_QPA_PLATFORM"
          "SDL_VIDEODRIVER"
          "GTK_IM_MODULE"
          "QT_IM_MODULE"
          "XMODIFIERS"
          "INPUT_METHOD"
          "SDL_IM_MODULE"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
          "LANG"
          "LC_CTYPE"
          "LC_ALL"
        ];
      };
      wrapperFeatures.gtk = true;
      xwayland = true;

      # Keep the native Sway configuration in a searchable standalone file,
      # while Home Manager still validates and installs it.
      config = null;
      extraConfigEarly = swayConfig;
    };
  };
}
