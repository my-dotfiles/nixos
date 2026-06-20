{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.sway;
  mod = "Mod4";
  terminal = "alacritty";
  menu = "fuzzel";
  primaryOutput = "DP-1";
  laptopOutput = "eDP-1";
  flclashAppId = "com.follow.clash";
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
  wallpaper = "${config.home.homeDirectory}/Pictures/图片/walls/abstract/a_blue_and_orange_background.jpg";
  swaymsg = lib.getExe' pkgs.sway "swaymsg";
  wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
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
  workspaceOutputAssign =
    (builtins.map (workspace: {
      inherit (workspace) name;
      workspace = workspace.name;
      output = primaryOutput;
    }) (builtins.filter (workspace: lib.toInt workspace.name <= 5) workspaces))
    ++ (builtins.map (workspace: {
      inherit (workspace) name;
      workspace = workspace.name;
      output = laptopOutput;
    }) (builtins.filter (workspace: lib.toInt workspace.name > 5) workspaces));
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
      flclashGui
      fuzzel
      jq
      mako
      (screenshot "area")
      (screenshot "edit")
      (screenshot "screen")
      (screenshot "window")
      swaybg
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
      settings = {
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
      };
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
        # Workstyle 会根据窗口 app_id/class 动态重命名 workspace，Waybar 直接显示结果。
        # 使用短字符而不是大图标，避免状态栏变宽或依赖特定图标字体。
        alacritty = "T";
        Alacritty = "T";
        firefox = "W";
        "org.mozilla.firefox" = "W";
        qutebrowser = "W";
        emacs = "E";
        "emacsclient" = "E";
        zed = "E";
        "dev.zed.Zed" = "E";
        thunar = "F";
        "org.gnome.Nautilus" = "F";
        thunderbird = "M";
        steam = "S";
        Steam = "S";
        "com.follow.clash" = "C";
        FlClash = "C";
        "com.mitchellh.ghostty" = "T";
        ghostty = "T";
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
        position = "bottom";
        output = [ primaryOutput ];
        height = 24;
        spacing = 8;

        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [ ];
        modules-right = [
          "tray"
          "network"
          "pulseaudio"
          "clock"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
          # Workstyle 会把 workspace 名称改为「编号: 窗口字符」，这里显示完整名称。
          format = "{name}";
        };
        tray = {
          icon-size = 16;
          spacing = 8;
        };
        network = {
          interval = 5;
          format-wifi = "W {signalStrength}%";
          format-ethernet = "E";
          format-disconnected = "N/A";
          tooltip = false;
        };
        pulseaudio = {
          format = "V {volume}%";
          format-muted = "V mute";
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          tooltip = false;
        };
        clock = {
          format = "{:%m-%d %H:%M}";
          tooltip-format = "{:%Y-%m-%d %A}";
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
          padding: 0 7px;
        }

        #workspaces button.focused,
        #workspaces button.visible {
          background: #7fc8ff;
          color: #111318;
        }

        #mode,
        #tray,
        #network,
        #pulseaudio,
        #clock {
          padding: 0 8px;
        }
      '';
    };

    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = true;
      wrapperFeatures.gtk = true;

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
          };
        };

        output = {
          # 主显示器：24 寸 2560x1440，放在全局坐标原点，也就是左侧。
          ${primaryOutput} = {
            mode = "2560x1440@165.001Hz";
            scale = "1.25";
            position = "0 0";
          };
          # 笔记本内屏：位于 DP-1 右侧。
          # DP-1 使用 1.25 缩放后逻辑宽度是 2048，所以 eDP-1 的 x 从 2048 开始。
          ${laptopOutput} = {
            mode = "1920x1080@120.030Hz";
            scale = "1.5";
            position = "2048 0";
          };
        };

        # 关闭 Sway 内置 swaybar，改由 Waybar 提供底部状态栏。
        bars = [ ];

        startup = [
          { command = "${setWallpaper}"; }
          {
            command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP GTK_IM_MODULE QT_IM_MODULE XMODIFIERS INPUT_METHOD SDL_IM_MODULE LANG LC_CTYPE LC_ALL";
          }
          {
            command = "swayidle -w timeout 300 'lock-screen' timeout 600 'swaymsg output * power off' resume 'swaymsg output * power on' before-sleep 'lock-screen'";
          }
        ];

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

        # 启动后默认显示 workspace 1；workspace 1-5 固定到主显示器，6-10 固定到内屏。
        defaultWorkspace = "workspace number 1";
        workspaceOutputAssign = builtins.map (item: {
          workspace = item.workspace;
          output = item.output;
        }) workspaceOutputAssign;

        keybindings = {
          "${mod}+Tab" = "workspace next";
          "${mod}+Shift+Tab" = "workspace prev";

          "${mod}+Return" = "exec ${terminal}";
          "${mod}+d" = "exec ${menu}";
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
        for_window [app_id="firefox" title="^Picture-in-Picture$"] floating enable, sticky enable
        for_window [window_role="pop-up"] floating enable
        for_window [window_role="bubble"] floating enable
        for_window [window_role="dialog"] floating enable
        for_window [window_type="dialog"] floating enable
      '';
    };
  };
}
