{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.sway;
  mod = "Mod4";
  appRunner = "${lib.getExe' pkgs.systemd "systemd-run"} --user --scope --slice=app.slice --quiet --collect --";
  terminal = "${appRunner} ${lib.getExe pkgs.alacritty}";
  menu = "${lib.getExe pkgs.fuzzel} --launch-prefix='${appRunner}'";
  fileManager = "xdg-open ${config.home.homeDirectory}";
  primaryOutput = "DP-1";
  laptopOutput = "eDP-1";
  flclashAppId = "com.follow.clash";
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
  wallpaper = "${config.home.homeDirectory}/Pictures/图片/walls/nord/a_cat_walking_on_a_hill.png";
  swaymsg = lib.getExe' pkgs.sway "swaymsg";
  wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
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
  directionKeys = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
    Left = "left";
    Down = "down";
    Up = "up";
    Right = "right";
  };
  workspaces =
    (builtins.map (n: {
      key = builtins.toString n;
      name = builtins.toString n;
    }) (lib.range 1 9))
    ++ [
      {
        key = "0";
        name = "10";
      }
    ];
  mkDirectionBindings =
    prefix: command:
    lib.mapAttrs' (
      key: direction: lib.nameValuePair "${mod}+${prefix}${key}" "${command} ${direction}"
    ) directionKeys;
  mkWorkspaceBindings =
    prefix: command:
    lib.listToAttrs (
      builtins.map (
        workspace: lib.nameValuePair "${mod}+${prefix}${workspace.key}" "${command} ${workspace.name}"
      ) workspaces
    );
  resizeBindings = lib.mapAttrs (
    _key: direction:
    {
      left = "resize shrink width 10px";
      down = "resize grow height 10px";
      up = "resize shrink height 10px";
      right = "resize grow width 10px";
    }
    .${direction}
  ) directionKeys;
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
in
{
  options.myHome.desktop.sway.enable = lib.mkEnableOption "Sway compositor user configuration";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      closeWindow
      blueman
      flclashGui
      fuzzel
      jq
      libnotify
      networkmanagerapplet
      pavucontrol
      polkit_gnome
      powerMenu
      (screenshot "area")
      (screenshot "edit")
      (screenshot "screen")
      (screenshot "window")
      swaybg
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

    services.network-manager-applet.enable = true;
    services.blueman-applet = {
      enable = true;
      systemdTargets = [ "sway-session.target" ];
    };

    xsession.preferStatusNotifierItems = true;

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
          format-wifi = "W {signalStrength}%";
          format-ethernet = "E";
          format-disconnected = "N/A";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };
        bluetooth = {
          format = "B";
          format-disabled = "B off";
          format-connected = "B {num_connections}";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          on-click = "blueman-manager";
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

    systemd.user.services.network-manager-applet.Service = {
      Restart = "on-failure";
      RestartSec = 2;
    };

    systemd.user.services.blueman-applet.Service = {
      Restart = "on-failure";
      RestartSec = 2;
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

      config = {
        modifier = mod;
        terminal = terminal;
        menu = menu;
        # 不留窗口间距：平铺窗口直接吃满可用区域，只保留顶部状态栏占用的空间。
        gaps = {
          inner = 0;
          outer = 0;
        };
        fonts = {
          names = [ "Maple Mono NF CN" ];
          size = 10.0;
        };

        input = {
          "type:keyboard" = {
            xkb_layout = "us";
            xkb_options = "ctrl:nocaps";
          };
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            events = "disabled_on_external_mouse";
          };
        };

        output = {
          # 主显示器：24 寸 2560x1440，放在全局坐标原点，也就是左侧。
          ${primaryOutput} = {
            mode = "2560x1440@165Hz";
            scale = "1.25";
            position = "0 0";
          };
          # 笔记本内屏：使用原生 16:10 模式。Kanshi 会在外屏连接时将其关闭。
          ${laptopOutput} = {
            mode = "2560x1600@120Hz";
            scale = "1.60";
            position = "0 0";
          };
        };

        # 关闭 Sway 内置 swaybar，改由 Waybar 提供顶部状态栏。
        bars = [ ];

        window = {
          border = 0;
          titlebar = false;
        };

        floating = {
          border = 2;
          modifier = mod;
          titlebar = true;
        };

        colors = {
          focused = {
            border = "#7fc8ff";
            background = "#111318";
            text = "#e6edf3";
            indicator = "#7fc8ff";
            childBorder = "#7fc8ff";
          };
          unfocused = {
            border = "#30363d";
            background = "#111318";
            text = "#8b949e";
            indicator = "#30363d";
            childBorder = "#30363d";
          };
        };

        # Kanshi 切换输出时由 Sway 自动迁移工作区，避免工作区绑定到已禁用的显示器。
        defaultWorkspace = "workspace number 1";

        keybindings = {
          "${mod}+Tab" = "workspace next";
          "${mod}+Shift+Tab" = "workspace prev";

          "${mod}+Return" = "exec ${terminal}";
          "${mod}+d" = "exec ${menu}";
          "${mod}+Shift+f" = "exec ${fileManager}";
          "${mod}+Shift+q" = "exec close-sway-window";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+e" =
            "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";

          "${mod}+b" = "splith";
          "${mod}+v" = "splitv";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+f" = "fullscreen";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
          "${mod}+a" = "focus parent";

          "${mod}+Shift+minus" = "move scratchpad";
          "${mod}+minus" = "scratchpad show";
          "${mod}+r" = "mode resize";

          "${mod}+Alt+l" = "exec lock-screen";
          "${mod}+Shift+a" = "exec pavucontrol";
          "${mod}+Shift+b" = "exec blueman-manager";
          "${mod}+Shift+d" = "exec wdisplays";
          "${mod}+Shift+n" = "exec nm-connection-editor";
          "${mod}+Escape" = "exec sway-power-menu";
          "${mod}+n" = "exec makoctl dismiss";
          "${mod}+Ctrl+n" = "exec makoctl dismiss --all";

          "--locked XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "--locked XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "--locked XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          "--locked XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "--locked XF86AudioPlay" = "exec playerctl play-pause";
          "--locked XF86AudioPause" = "exec playerctl play-pause";
          "--locked XF86AudioPrev" = "exec playerctl previous";
          "--locked XF86AudioNext" = "exec playerctl next";
          "--locked XF86AudioStop" = "exec playerctl stop";
          "--locked XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "--locked XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
          # 参照 Niri：Ctrl+Shift+Mod+4 区域截图，Alt+Ctrl+Shift+Mod+4 全屏截图。
          "Ctrl+Shift+${mod}+4" = "exec screenshot-area";
          "Alt+Ctrl+Shift+${mod}+4" = "exec screenshot-screen";
          "Print" = "exec screenshot-screen";
          "Shift+Print" = "exec screenshot-edit";
          "Ctrl+Print" = "exec screenshot-window";
        }
        // mkDirectionBindings "" "focus"
        // mkDirectionBindings "Shift+" "move"
        // mkWorkspaceBindings "" "workspace number"
        // mkWorkspaceBindings "Shift+" "move container to workspace number";

        modes.resize = resizeBindings // {
          Return = "mode default";
          Escape = "mode default";
        };
      };

      extraConfig = ''
        workspace_auto_back_and_forth yes
        focus_on_window_activation smart
        popup_during_fullscreen smart
        mouse_warping output

        for_window [app_id="firefox" title="^Picture-in-Picture$"] floating enable, sticky enable
        for_window [app_id="^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|wdisplays|swappy)$"] floating enable, resize set 900 650, move position center
        for_window [window_role="pop-up"] floating enable
        for_window [window_role="bubble"] floating enable
        for_window [window_role="dialog"] floating enable
        for_window [window_type="dialog"] floating enable
        for_window [window_type="utility"] floating enable
        for_window [window_type="toolbar"] floating enable
        for_window [app_id=".*"] inhibit_idle fullscreen
        for_window [class=".*"] inhibit_idle fullscreen
      '';
    };
  };
}
