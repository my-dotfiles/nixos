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
- Homebrew 由 nix-darwin 接管，当前主要负责 GUI App、字体、macOS 系统组件和少量
  更新较快的 CLI；activation 不会自动更新、升级或清理已有 Brew 软件。
- Nix、shell、Git/GitHub、tmux、yazi、lazygit、fzf、direnv 等 CLI 工作流。
- 常用开发工具和语言服务器。
- 用户字体和 fontconfig。
- Codex 相关 nodejs 依赖和 `codex-proxy` wrapper。

没有迁移：

- 浏览器和浏览器配置，macOS 上已有。
- NixOS 系统配置、硬件配置、Wayland/Sway/Niri、fcitx5、MIME、lockscreen。
- sops secret、邮件同步、rclone/systemd 服务。

默认 shell 由 nix-darwin 设置为 Nix 管理的 fish，Home Manager 也会把用户会话里的
`SHELL` 指向同一个 fish。切换后可以用下面的命令确认：

```sh
dscl . -read /Users/yurikon UserShell
echo $SHELL
fish --version
```

Emacs 在 macOS 上使用 Homebrew formula `d12frosted/emacs-plus/emacs-plus@30` 提供
更贴近 macOS、Apple Silicon 友好的 GUI binary；Home Manager 继续管理
`~/.emacs`、`~/.emacs.d/init.el`、`early-init.el`、`~/.local/bin/emacs*` wrapper 和
用户级 `launchd` daemon。elisp 包不由 Brew Emacs 启动时联网安装，而是由 Nix 用
`pkgs.emacs30` 生成 ELPA package closure，再在 `init.el` 中加入 `package-directory-list`。
登录后 `launchd` 会以 `emacs --fg-daemon` 启动后台服务，`emacsclient -c` 或
`emacsclient -t` 会连接到这个 daemon。

Homebrew 清单已经从首次迁移用的全量快照收窄为 macOS 应用层和少量快速更新工具。
Homebrew 模块提供几个迁移阶段开关：

- `myDarwin.apps.homebrew.includeFormulae`：保留少量 Brew formula，例如 `uv` 和 `yarn`。
- `myDarwin.apps.homebrew.includeLegacyEmacsTaps`：默认关闭；只保留历史比较用的
  `railwaycat/emacsmacport` tap，不影响当前 `emacs-plus@30`。
- `myDarwin.apps.homebrew.cleanupMode`：默认 `"none"`；由于 `emacs-plus@30` 依赖一批
  Brew formula，不要在常规 activation 中自动 cleanup，避免误清依赖链。

从 Brew 迁出的通用 CLI、构建工具、LSP 和 formatter 由 Home Manager 管理。

npm 由 Home Manager 管理用户层安装行为：`~/.npmrc` 固定 `prefix` 到
`~/.npm-global`，cache 到 `~/.cache/npm`，并关闭 `fund`、`audit` 和 update notifier。
因此 `npm install -g ...` 不需要 sudo，也不会写入 Nix store 或 Homebrew prefix。

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
