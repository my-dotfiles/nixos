# macOS Nix 配置

这个 worktree 是 Yurikon 的 macOS Nix 配置。主入口使用 nix-darwin 管系统层、
Homebrew 和 Home Manager；同时保留 standalone Home Manager 输出，方便只验证用户层。

## 入口

```text
flake.nix                         flake inputs、darwinConfigurations 和 homeConfigurations。
hosts/macos/default.nix           nix-darwin 主机入口。
hosts/macos/home.nix              Home Manager 用户入口。
home.nix                          兼容入口，import hosts/macos/home.nix。
modules/darwin/profiles/macos.nix nix-darwin profile。
modules/home/profiles/macos.nix   macOS profile，集中启用模块。
```

`flake.nix` 提供三个 nix-darwin 配置：

- `yurikon-macos`：默认 Apple Silicon，等同于 `aarch64-darwin`。
- `yurikon-macos-aarch64`：Apple Silicon。
- `yurikon-macos-x86_64`：Intel Mac。

同名 `homeConfigurations` 仍保留给 standalone Home Manager 求值。

## 首次应用

在 macOS 上 clone 或进入这个 worktree 后，首次安装 nix-darwin：

```sh
sudo -H nix run nix-darwin/master#darwin-rebuild -- switch --flake path:$PWD#yurikon-macos
```

Intel Mac 使用：

```sh
sudo -H nix run nix-darwin/master#darwin-rebuild -- switch --flake path:$PWD#yurikon-macos-x86_64
```

后续可以使用已安装的 `darwin-rebuild`：

```sh
sudo -H darwin-rebuild switch --flake path:$PWD#yurikon-macos
```

使用 `path:` 是有意的，它能看到尚未加入 Git 的本地模块。

如果首次 activation 报告 `/etc` 下已有文件会被覆盖，例如 `/etc/bashrc`，先确认文件里
没有手写的重要配置，再按提示保留备份：

```sh
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
```

随后重新运行 `darwin-rebuild switch`。

## 检查和格式化

```sh
nix flake check --no-build path:/home/yurikon/nixos-config-macos
nixfmt flake.nix home.nix hosts/**/*.nix modules/**/*.nix
```

在 macOS 上把检查路径替换成实际 checkout 路径。

## 当前迁移范围

已迁移：

- Emacs 配置和 Nix 管理的 Emacs package 集合。
- nix-darwin 系统入口、Determinate Nix 兼容设置、常用 macOS defaults。
- Homebrew 由 nix-darwin 接管，当前先声明已有 tap、formula 和 cask 清单；activation
  不会自动更新、升级或清理已有 Brew 软件。
- Nix、shell、Git/GitHub、tmux、yazi、lazygit、fzf、direnv 等 CLI 工作流。
- 常用开发工具和语言服务器。
- 用户字体和 fontconfig。
- Codex 相关 nodejs 依赖和 `codex-proxy` wrapper。

没有迁移：

- 浏览器和浏览器配置，macOS 上已有。
- NixOS 系统配置、硬件配置、Wayland/Sway/Niri、fcitx5、MIME、lockscreen。
- sops secret、邮件同步、rclone/systemd 服务。

Emacs 在 macOS 上使用 Nixpkgs 的 `emacs30-macport`。这比通用 `emacs` 更贴近
macOS GUI，同时仍能让 Nix 管理 Emacs package 集合。Homebrew 已接入，适合后续接管
不适合 Nix 管的 GUI App；当前没有擅自迁移浏览器或已有 Brew 软件。

Homebrew 清单目前偏保守，目标是让首次 `darwin-rebuild` 先可运行。Homebrew 模块提供
几个迁移阶段开关：

- `myDarwin.apps.homebrew.includeFormulae`：暂时保留已有 formula 清单；当 CLI 工具由 Nix
  覆盖并验证后，可以改为 `false`。
- `myDarwin.apps.homebrew.includeLegacyEmacsTaps`：暂时保留旧 Emacs tap；确认不再需要 Brew
  Emacs 后可以改为 `false`。
- `myDarwin.apps.homebrew.cleanupMode`：默认 `"none"`；清单稳定后可先改为 `"check"`，
  再考虑 `"uninstall"`，不要直接跳到 `"zap"`。

当前 nix-darwin 已开始接管 Finder、Dock、截图、触控板、登录窗口和菜单栏时钟等 macOS
defaults。更高风险的系统服务、网络、防火墙、隐私授权和浏览器状态暂不纳入。

## 模块约定

Darwin 模块使用 `myDarwin.*.enable` 命名空间。Home Manager 模块继续使用
`myHome.*.enable` 命名空间。profile 只负责组合模块和设置开关，具体实现放在
`modules/darwin/*` 或 `modules/home/*` 的 leaf module 中。

macOS profiles 位于：

```text
modules/darwin/profiles/macos.nix
modules/home/profiles/macos.nix
```

如果以后需要迁移更多应用，优先新增或复用 leaf module，然后在 macOS profile 中启用。
浏览器、系统服务、secret 明文、运行时缓存、日志、数据库和会话状态不应进入仓库。
