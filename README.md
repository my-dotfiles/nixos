# NixOS 配置

这个仓库是 Yurikon 这台 NixOS 工作站的声明式配置。它用一个 flake 同时管理：

- NixOS 系统级配置
- Home Manager 用户级配置

这台机器从 Arch Linux 迁移而来。迁移时使用的备份位于仓库外：

```text
/run/media/yurikon/Momonga/MyData/Backup/nixos-migration-2026-05-28/
```

备份只作为参考资料使用。不要把运行时状态、缓存、token、私钥、浏览器会话、
生成数据库等内容复制进这个仓库。

## 配置入口

```text
flake.nix                   flake inputs 和 nixosConfigurations.nixos。
hosts/nixos/default.nix     这台机器的系统入口。
home.nix                    yurikon 用户的 Home Manager 入口。
configuration.nix           兼容入口，只 import hosts/nixos。
hardware-configuration.nix  由 nixos-generate-config 生成的硬件配置。
```

当前推荐的系统入口是 `hosts/nixos/default.nix`。根目录的 `configuration.nix`
只是为了从 `/etc/nixos` 迁移过来时更容易理解；新的系统配置通常应该放到
`modules/system`。

## 目录结构

```text
hosts/
  nixos/             单台机器的 imports 和 host-only 配置。

modules/
  system/
    core/            启动、Nix 设置、locale、用户、基础系统包。
    desktop/         桌面会话的系统级集成。
    services/        PipeWire、OpenSSH、打印等系统服务。
    profiles/        系统模块组合。

  home/
    core/            XDG、shell/session、稳定的用户默认行为。
    cli/             终端工具和命令行工作流。
    desktop/         GUI 应用、字体、MIME、fcitx5、Niri 配置。
    development/     编辑器和全局开发工具。
    secrets/         本地 secret 文件接入；不存放 secret 明文。
    profiles/        Home Manager 模块组合。
```

## 常用命令

切换完整系统配置，包括 Home Manager：

```sh
sudo nixos-rebuild switch --flake path:/home/yurikon/nixos-config#nixos
```

只检查求值，不实际构建：

```sh
nix flake check --no-build path:/home/yurikon/nixos-config
```

格式化 Nix 文件：

```sh
nixfmt flake.nix home.nix configuration.nix hosts/**/*.nix modules/**/*.nix
```

这里使用 `path:` 是有意的。当前工作区里有不少新文件还没有加入 Git，普通
`nix flake check` 会使用 Git 视角，可能看不到未跟踪文件。

## 系统配置

系统模块使用 `mySystem.*` 命名空间，并通过 feature flag 启用。一个 leaf
module 通常长这样：

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.services.example;
in
{
  options.mySystem.services.example.enable =
    lib.mkEnableOption "example system service";

  config = lib.mkIf cfg.enable {
    services.example.enable = true;
  };
}
```

系统功能在 `modules/system/profiles/workstation.nix` 中启用。只属于这台机器的
配置，例如 `networking.hostName`、`system.stateVersion`、硬件配置 import，
放在 `hosts/nixos/default.nix`。

## Home Manager

Home Manager 模块使用 `myHome.*` 命名空间。`home.nix` 应保持很小，只设置：

- 用户名
- home 目录
- Home Manager stateVersion
- workstation profile import

用户功能在 `modules/home/profiles/workstation.nix` 中启用。leaf module 优先使用
Home Manager 的结构化选项，例如 `programs.*`、`services.*`、`xdg.configFile`、
`home.file`。

当前全局编辑器是 Emacs。项目专属的 LSP、编译器、SDK、formatter 应优先放到项目
自己的 `flake.nix` 或 `devShell` 中。全局只保留通用的 Nix 和 shell 维护工具。

## 桌面环境

目标桌面是 Niri + Noctalia v5。

Niri 的系统级集成位于：

```text
modules/system/desktop/niri.nix
```

这里负责启用 Niri、GDM 登录管理器、portal、常用 Wayland 工具、
power/bluetooth 相关服务，并从官方 v5 flake package 安装 Noctalia：

```nix
inputs.noctalia.packages.${system}.default
```

Niri 的用户级配置位于：

```text
modules/home/desktop/niri.nix
```

Niri 启动时会用 v5 命令拉起 Noctalia：

```kdl
spawn-at-startup "noctalia"
```

Noctalia 由 Nix 安装，但它的用户设置不由 Home Manager 管理。后续通过
Noctalia 自己的 UI 或本地配置文件设置即可。

GNOME Desktop 有意不启用。当前保留 GDM 只是作为登录管理器，方便在登录界面选择
Niri session。

## 迁移规则

继续从备份迁移内容时，先分类再加入仓库：

- 系统启动、用户、服务、硬件、网络：放入 `modules/system`。
- shell、终端工具、编辑器配置、用户应用：放入 `modules/home`。
- 单机特有配置和临时迁移例外：放入 `hosts/nixos`。
- 运行时状态、缓存、日志、socket、history：默认不纳入管理。
- token、credential、私钥、cookie、密码库：绝不提交。
- 项目专属 LSP、SDK、编译器、formatter：放到项目 flake。

模块命名应使用语义名称，例如 `cli/git.nix`、`desktop/fonts.nix`、
`services/pipewire.nix`。避免使用 `misc.nix` 这类无法表达边界的名字。

## Secrets

`modules/home/secrets` 只描述本地 secret 文件如何被 source，不存放 secret 明文。

当前本地 hook 会查找：

```text
~/.config/secrets/api-keys.bash
~/.config/secrets/api-keys.fish
```

这些文件属于本机状态，应留在 Git 外。

## 备注

`hardware-configuration.nix` 由 `nixos-generate-config` 生成。它应该保持小而专注，
只放硬件和文件系统相关配置。如果某个设置是可复用策略，而不是硬件检测结果，就应
移动到 `modules/system` 的对应模块中。
