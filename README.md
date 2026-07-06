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
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake path:$PWD#yurikon-macos
```

Intel Mac 使用：

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake path:$PWD#yurikon-macos-x86_64
```

后续可以使用已安装的 `darwin-rebuild`：

```sh
sudo darwin-rebuild switch --flake path:$PWD#yurikon-macos
```

使用 `path:` 是有意的，它能看到尚未加入 Git 的本地模块。

## 检查和格式化

```sh
nix flake check --no-build path:/home/yurikon/nixos-config-macos
nixfmt flake.nix home.nix hosts/**/*.nix modules/**/*.nix
```

在 macOS 上把检查路径替换成实际 checkout 路径。

## 当前迁移范围

已迁移：

- Emacs 配置和 Nix 管理的 Emacs package 集合。
- nix-darwin 系统入口、Nix daemon 设置、少量 macOS defaults。
- Homebrew 由 nix-darwin 接管，但 activation 不会自动更新、升级或清理已有 Brew 软件。
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
