# NixOS → Gentoo（OpenRC）迁移纲要

> 状态：第一版盘点
>
> 基线：`92e338f`（2026-07-24）
>
> 范围：只整理现有配置的可迁移性，不生成 Gentoo 配置，也不执行迁移。

## 1. 目标与判断标准

这次迁移要保存的不是 Nix 表达式本身，而是它们表达的配置意图、原生配置和机器事实。
目标 Gentoo 机器采用 **AMD CPU + AMD GPU + OpenRC**。因此当前机器的
Intel/NVIDIA 混合显卡配置只作为旧机事实记录，不进入目标配置。

同一项配置可能同时包含可直接复用和必须重写的部分，例如：

- `hardware-configuration.nix` 的文件系统 UUID 是旧机事实，可以作为数据迁移核对依据；
  NixOS 的 `fileSystems` 表达式不能复制到 Gentoo，新机器的 UUID 也会不同。
- `modules/home/desktop/sway/config` 大部分是原生 Sway 语法，可以继续使用；
  其中的占位符、输出名、Nix store 路径和 systemd 用户会话编排必须替换。
- sops 加密文件可以保留，但 sops-nix 的自动解密、文件权限和 shell 注入流程不能照搬。

本文采用四个迁移等级：

| 等级 | 含义 | 迁移动作 |
| --- | --- | --- |
| A | 原生配置，可直接复用 | 复制到新 dotfiles，再做路径和版本核对 |
| B | 配置意图可复用，但要重新落地 | 改写成 Gentoo/OpenRC、PAM、内核或普通配置文件 |
| C | 需要先做更精细的设计或实机验证 | 先记录依赖、状态、启动顺序和验证方法 |
| N | NixOS/Home Manager 特有，或与目标硬件冲突 | 不迁移；只保留其表达的意图或留作历史参考 |

“可迁移”不等于“可以盲目复制”。所有硬件名称、包名、USE flag、服务名和路径都应在
Gentoo 实机上重新确认。

## 2. 当前配置基线与目标差异

### 2.1 当前机器事实（仅用于盘点）

- 主机名：`nixos`。
- 架构：`x86_64-linux`。
- CPU：Intel，启用 `kvm-intel` 和 Intel microcode。
- GPU：Intel 核显 + NVIDIA 独显 PRIME offload。
  - Intel：`PCI:0:2:0`
  - NVIDIA：`PCI:1:0:0`
  - NVIDIA DRM modeset、open kernel module、细粒度电源管理已启用。
- 桌面：Sway；greetd/tuigreet 登录。
- 未启用的备用桌面：Niri/Noctalia、Plasma。
- 文件系统：
  - `/`：ext4，UUID `675b6f26-ba72-423c-8704-376ea011ed1c`
  - `/boot`：vfat，UUID `B552-1C1F`，当前权限选项为 `fmask=0077,dmask=0077`
  - `/home`：ext4，UUID `e6ea7aa4-834f-47c0-8843-8a4ff88d3a55`
  - `/data/media`：ext4，UUID `fef36a86-961e-4148-a2c6-6e56ec9a707f`
- 交换与内存压力：
  - `/home/.swapfile`，16 GiB，优先级 10
  - zram 使用 zstd，容量为内存的 25%，优先级 100
  - `vm.swappiness=20`
  - systemd-oomd 保护用户 slice
- 用户：`yurikon`，Fish 登录 shell；有效附加组意图包括
  `wheel`、`networkmanager`、`docker`、`libvirtd`。

### 2.2 目标硬件边界

下列内容明确不迁移：

- Intel CPU microcode、`kvm-intel` 和 Intel CPU profile；
- NVIDIA 驱动、NVIDIA open kernel module、`nvidia-settings`；
- PRIME bus ID、PRIME offload command 和细粒度 NVIDIA 电源管理；
- `__NV_PRIME_RENDER_OFFLOAD`、`__GLX_VENDOR_LIBRARY_NAME`、
  `__VK_LAYER_NV_optimus`；
- “让 Sway 固定使用 Intel、游戏使用 NVIDIA”的所有特殊处理；
- NVIDIA 专属的 32 位 OpenGL/Vulkan 用户空间。

目标 Gentoo 需要重新设计：

- AMD CPU microcode 和 `kvm-amd`；
- AMDGPU 内核驱动、固件加载、Mesa OpenGL/Vulkan；
- AMD GPU 的硬件编解码、32 位游戏栈和电源管理；
- 新机器的 PCI ID、磁盘 UUID、输出名、分辨率、刷新率和缩放；
- 是否沿用旧机的分区、swap/zram 和休眠策略。

### 2.3 当前服务状态意图

已配置：

- NetworkManager、SSH、PipeWire、CUPS/Avahi、SANE
- Bluetooth/Blueman、UPower、power-profiles-daemon
- GVfs、udisks2、Tumbler、gnome-keyring、Polkit
- Docker、libvirt/virt-manager、Flatpak
- Jellyfin、Mihomo、Tailscale、usbmuxd
- Thunar、Steam/Gamemode

特殊的启动策略：

- Docker 已安装，但 systemd service/socket 没有加入启动目标，意图是按需手动启动。
- Jellyfin 已安装并开放防火墙，但 `autoStart=false`，意图是按需启动。
- rclone 的 gdrive/onedrive 用户挂载已定义，但 `autoStart=false`。
- Mihomo 是系统级 TUN 代理，配置持久化在 `/etc/mihomo/config.yaml`。

### 2.4 当前用户环境

- Shell/CLI：Fish、Bash、Starship、Git、gh、SSH、Yazi、Zellij，以及常用终端工具。
- 编辑器：Emacs 31 PGTK + 原生 Elisp；Home Manager 通过 systemd 用户 socket
  启动 daemon。
- 桌面：Sway、Waybar、Mako、Kanshi、Workstyle、Fuzzel、Cliphist、Wob、
  Udiskie、Polkit agent。
- 输入法：Fcitx5 拼音，自然码双拼和一组自定义行为。
- 字体：Noto/思源/更纱/霞鹜/文泉驿/Maple Mono/Nerd Fonts，并有自定义
  fontconfig fallback。
- 邮件：Gmail、iCloud、QQ、163；mbsync/msmtp/mu/mu4e；每 10 分钟同步并重建索引。
- 密钥：sops + age；仓库只保存加密数据，age 私钥位于用户配置目录。
- 云盘：rclone 的 Google Drive 和 OneDrive FUSE 挂载。

## 3. A 级：应优先保存的原生配置

这些内容最适合从 Nix 模块中抽成普通 dotfiles，作为 Gentoo 版本的稳定输入。

| 当前来源 | 可保留内容 | 迁移时的小改动 |
| --- | --- | --- |
| `modules/home/desktop/sway/config` | 输入、窗口、工作区、快捷键和窗口规则 | 替换三个占位符；输出段按新 AMD 机器重做 |
| `modules/home/development/emacs/init.el` | Emacs 主配置 | 替换 Nix 注入的 `mmdc`、`wl-copy` 绝对路径 |
| `modules/home/development/emacs/early-init.el` | Emacs early init | 核对 Emacs/Gentoo 包版本 |
| `modules/home/cli/zellij/config.kdl` | Zellij 配置 | 核对 Zellij 版本语法 |
| `desktop/fcitx5.nix` 中的文本 | profile、拼音、Classic UI、标点、Wayland 配置 | 拆为 `~/.config/fcitx5/**`；确认插件名称存在 |
| `desktop/fonts.nix` 中的 XML | fontconfig 渲染与 fallback | 拆为 `~/.config/fontconfig/**`；按实际字体名修正 |
| `desktop/mime.nix` | MIME 默认应用映射 | 生成 `~/.config/mimeapps.list`，核对 desktop ID |
| `cli/glow.nix` | `glow.yml` | 直接落到 XDG config |
| `desktop/sway.nix` 中的配置数据 | Mako、Kanshi、Waybar、Workstyle、Wob、networkmanager-dmenu | 转换为各程序原生配置文件 |
| `cli/*` 中的设置 | Git、gh、Starship、Alacritty、htop、Yazi、shell alias | 转为程序原生配置；删除 Nix profile 路径 |
| `desktop/mpv.nix` | mpv 播放、Vulkan、语言偏好 | 转为 `mpv.conf`，在 AMD GPU 上重测硬解 |
| `communication/mail.nix` | 邮箱地址、IMAP/SMTP、maildir 与同步策略 | 生成 mbsyncrc/msmtprc 和 mu4e 配置；密码仍从外部命令读取 |
| `development/codex.nix`、`pi.nix` | 本地代理 wrapper 的行为 | 改用普通脚本并确保不包含 token |

### 3.1 可直接保留，但不应提交的本机状态

下列内容是迁移输入，却不能进入 Git：

- `~/.config/sops/age/keys.txt`
- SSH 私钥、known_hosts 中不希望公开的条目
- `~/.config/rclone/rclone.conf` 及 OAuth token
- 解密后的邮箱密码和 API key
- Mihomo 订阅 URL、下载后的 provider 文件和选择状态
- 邮件正文与 mu 索引、浏览器会话、Steam 登录状态、容器/虚拟机镜像
- Fcitx 用户词库、剪贴板历史、应用数据库和缓存

这些状态必须使用单独的加密备份清单迁移，不能靠复制仓库完成。

## 4. B/C 级：需要重新落地或精细设计的系统配置

### 4.1 启动、内核和文件系统（B/C）

| 当前意图 | Gentoo/OpenRC 侧工作 | 需要精细确认 |
| --- | --- | --- |
| systemd-boot，保留 15 个配置 | 决定继续使用 systemd-boot 还是换其他 bootloader；生成内核项 | systemd-boot 不代表使用 systemd init，但更新流程需另建 |
| nixpkgs 默认内核 | 选择 distribution kernel 或自编译内核 | AMDGPU、Sway、TUN、FUSE、KVM、容器所需内核选项 |
| 旧机 initrd 模块清单 | 根据新 AMD 机器重新探测并写入 initramfs | 不能照抄旧机的存储、Thunderbolt 和控制器模块 |
| Intel microcode | 不迁移，改为 AMD microcode | bootloader/initramfs 的具体加载方式 |
| 旧机四个文件系统及挂载选项 | 根据新机实际分区生成 `/etc/fstab` | 哪些数据盘复用、哪些 UUID 会变化 |
| 16 GiB swapfile + 25% zram | 决定是否保留此策略；建立 OpenRC 启动逻辑和 sysctl | 新内存容量、创建时机、权限、优先级、休眠需求 |
| systemd-oomd | 选择可在 OpenRC 下使用的 OOM 策略 | 不能照搬 user slice；需重新定义内存压力策略 |

迁移前必须在旧机另存数据源清单，并在新机重新采集 `lspci -nnk`、`lsblk -f`、
`findmnt`、`lsmod`、EDID/输出名和内核命令行。旧仓库的生成配置不能替代新机探测。

### 4.2 Portage、AMD 图形栈与包策略（C）

NixOS 的包闭包隐藏了很多编译特性；Gentoo 必须显式决定：

- profile、稳定/测试关键字和许可证接受范围；
- Wayland/XWayland、PipeWire、Bluetooth、printing、scanner、FUSE、TUN、
  Vulkan、VA-API、AMDGPU、Polkit、PAM、keyring 相关特性；
- AMD GPU 对应的 Mesa/Vulkan 实现和固件；
- Steam/Wine 所需的 multilib 与 32 位 Mesa/Vulkan/音频栈；
- AMD CPU microcode、`kvm-amd` 和目标内核版本；
- Emacs PGTK、native compilation、tree-sitter、mu4e 和 PDF 支持；
- 哪些开发工具仍应全局安装，哪些改为项目自己的环境；
- NixOS 中存在、但 Gentoo 仓库未必以同名/同版本提供的软件。

这一阶段应根据目标 AMD 硬件、最终 Gentoo profile 和 `emerge --info` 生成
`package.use`、`package.accept_keywords`、`package.license`，不能直接从 Nix 包名猜测。

### 4.3 OpenRC 系统服务与 runlevel（B/C）

NixOS 的 `services.*.enable` 同时完成安装、用户组、目录、配置、依赖和启动。
Gentoo 需要把每一项拆开检查：

| 服务域 | 当前意图 | OpenRC 迁移重点 |
| --- | --- | --- |
| 网络 | NetworkManager；reverse-path check 关闭 | OpenRC runlevel、DNS 所有权、防火墙和 Mihomo TUN 的路由关系 |
| SSH | sshd 启用 | host key 的安全迁移、sshd_config、firewall、runlevel |
| 音频 | PipeWire + ALSA + Pulse 兼容 + 32 位 + rtkit | 用户会话启动、WirePlumber、PAM/DBus、实时权限、Steam 32 位 |
| 打印 | CUPS + Avahi/mDNS | OpenRC 依赖、nss-mdns、发现规则、firewall |
| 扫描 | SANE | backend、udev 权限、实际扫描仪验证 |
| Bluetooth | BlueZ + Blueman | bluetooth service、用户权限、agent 与桌面自启 |
| 桌面存储 | udisks2 + GVfs + Udiskie + Tumbler | DBus、Polkit rule、FUSE、会话 agent |
| Docker | 安装但默认不自启；每周 prune；本地代理 | 保持手动启动语义；独立 prune 任务；daemon.json；docker 组风险 |
| libvirt | libvirtd + virt-manager | daemon 形态、OpenRC 服务、网络、`kvm-amd` 权限 |
| Flatpak | 系统启用并添加 Flathub | portal、session bus、remote 的幂等初始化 |
| Jellyfin | 安装、开放端口、默认不自启 | 服务用户、媒体目录权限、手动启动、数据库状态的备份策略 |
| Tailscale | daemon + firewall | runlevel、认证状态、路由/防火墙和 Mihomo 共存 |
| usbmuxd | iPhone/iPad 配对 | udev、服务、pairing records 的迁移边界 |
| 电源 | UPower、power-profiles-daemon、lid/power key 策略 | AMD 平台能力；elogind/ACPI 责任边界；避免重复处理按键 |
| 定时任务 | Nix GC；邮件每 10 分钟同步 | Nix GC 若不保留 Nix则删除；邮件改用 cron 或会话级调度 |

Docker、Jellyfin 和 rclone 的“已配置但不自动启动”是必须保留的行为，不应在 Gentoo
中因为简单加入 `default` runlevel 而改变。

### 4.4 Mihomo（C，独立迁移子项目）

Mihomo 是当前最复杂的单项系统服务：

- 系统级 TUN，gVisor stack，自动路由和 DNS hijack；
- mixed port `7890`，controller `127.0.0.1:9090`；
- fake-IP、GeoIP/GeoSite、订阅 provider、健康检查；
- `/etc/mihomo/config.yaml` 只在首次缺失时创建；
- 运行前准备 geodata；
- 失败后 3 秒重启；
- `mihomoctl` 和订阅安装脚本直接调用 `systemctl`/`journalctl`；
- Nix daemon 和 Docker 另外注入本地代理。

迁移时需要：

1. 将不含订阅 URL 的基线配置保存为普通模板；
2. 单独实现 `/etc/init.d/mihomo` 和 `/etc/conf.d/mihomo`，声明网络、TUN、
   文件权限、pid/supervision 和 restart 行为；
3. 把 CLI 中的 `systemctl`/`journalctl` 改为 OpenRC 和目标日志方案；
4. 决定 geodata 的安装与更新来源；
5. 明确 Mihomo、NetworkManager、Tailscale、Docker 和防火墙的启动顺序；
6. 验证 DNS 泄漏、IPv6、局域网直连、休眠恢复和网络切换；
7. 订阅 URL 继续作为本机 secret，绝不写入仓库。

### 4.5 Sway 登录与桌面系统集成（C）

当前 NixOS 隐式提供了以下链路：

`greetd/tuigreet → PAM → 用户会话 → Sway → systemd --user target → 桌面服务`

Gentoo/OpenRC 下要重新决定并验证：

- greetd 是否继续使用，以及 PAM、环境变量、gnome-keyring 解锁如何接入；
- seat/session 管理由 elogind、seatd 或其他组合承担；
- Sway 如何在正确的 DBus 用户会话与 XDG runtime 目录中启动；
- Polkit agent、xdg-desktop-portal-wlr/gtk、PipeWire、WirePlumber 的启动顺序；
- lid/power key、suspend、lock-before-sleep 由谁负责；
- Sway 在 AMDGPU 上的渲染、Vulkan、硬件光标和休眠恢复行为；
- `DP-1`、`eDP-1` 只是旧机名称；新机器需要重建 Kanshi profile。

这是迁移的关键路径。在这条链路通过以前，不应先迁移大量 GUI 应用。

### 4.6 systemd 用户单元（C）

下列当前功能依赖 systemd 用户服务、socket 或 target，不能翻译成系统级 OpenRC
服务后就算完成：

- Sway session target 和环境导入；
- Polkit GNOME authentication agent；
- Fcitx5、swaybg、cliphist watcher；
- Wob FIFO socket activation；
- swayidle/lock-screen；
- Waybar、Kanshi、Workstyle、Mako、Udiskie；
- Emacs daemon/socket activation；
- mbsync 的 10 分钟 timer；
- gdrive/onedrive rclone mount。

需要先选择用户会话管理方式，再统一改写。可选方向包括由 Sway 原生 `exec`/包装脚本
管理，或使用专门的用户级 supervisor。无论选择哪种方式，都应保证：

- 服务随图形会话启动和退出，不以 root 身份运行；
- 可重启、可查看日志、不会重复启动；
- 正确继承 `WAYLAND_DISPLAY`、`SWAYSOCK`、DBus、Fcitx 和 XDG 环境；
- 锁屏在 suspend 之前已经真正建立；
- rclone/邮件/Emacs 这类非桌面服务不会被错误绑死在 Sway 生命周期。

## 5. NixOS system 模块逐项迁移判断

| 当前模块 | 等级 | 结论 |
| --- | --- | --- |
| `core/boot` | B/C | 保留“稳定内核优先”的意图；bootloader、内核和保留策略按 Gentoo 重做 |
| `core/locale` | A/B | 保留 `Asia/Shanghai`、`en_US.UTF-8` 主语言、中英文 LC 分工、US 键盘和 `ctrl:nocaps` |
| `core/networking` | B/C | 继续使用 NetworkManager；reverse-path、防火墙和 TUN/VPN 规则显式重做 |
| `core/nix` | N | 仅在 Gentoo 上继续使用 Nix 时才保留 flakes、timeout、unfree 和代理策略 |
| `core/nix-gc` | N | NixOS system generation 不存在；若保留 Nix，另建普通 store GC 策略 |
| `core/packages` | B | `vim/wget/git/git-lfs/curl/tree/unzip/file/parted/pciutils/usbutils/gparted/bubblewrap/firefox` 是基础软件愿望清单 |
| `core/swap` | C | 策略可参考，但容量必须按新 AMD 机器的内存与休眠需求重算 |
| `core/users` | B | 重建用户、Fish 登录 shell、wheel 和服务组；不要直接复制 UID/GID |
| `hardware-configuration.nix` | C/N | 只用于旧盘数据定位；新机必须重新探测 initramfs 模块、fstab 和 UUID |
| `hardware/cpu/intel` | N | 目标为 AMD；改成 AMD microcode 与 `kvm-amd` |
| `hardware/gpu/nvidia-prime` | N | 目标为 AMD GPU；PRIME、bus ID、驱动和 offload 全部删除 |
| `desktop/sway` | B/C | 软件选择可迁；greetd/PAM/seat/portal/Polkit/电源/会话启动需重建 |
| `desktop/thunar` | B | 保留 Thunar、archive/volman、GVfs、Tumbler、udisks2 的功能组合 |
| `desktop/steam` | B/C | 保留 Steam、Protontricks、Gamemode 和 32 位支持；删除 NVIDIA 环境并改测 AMDGPU |
| `services/docker` | B/C | 保留 Compose/Lazydocker、代理、手动启动和每周 prune 意图 |
| `services/flatpak` | B | 保留系统 Flatpak 和 Flathub；改为 Gentoo 上的幂等初始化 |
| `services/jellyfin` | C | 保留安装但不自启；数据、媒体权限、端口和硬解需另行设计 |
| `services/libvirt` | B/C | 保留 virt-manager 和手动管理能力；改用 AMD KVM 与 OpenRC 服务 |
| `services/mihomo` | C | 独立子项目；OpenRC、TUN、DNS、geodata、secret 和工具脚本均需重写 |
| `services/openssh` | B/C | 服务可迁；host key、配置、网络暴露和启动级别要安全核对 |
| `services/pipewire` | B/C | 功能组合可迁；OpenRC 用户会话、WirePlumber、rtkit 和 32 位库需重建 |
| `services/printing` | B/C | CUPS/Avahi 可迁；发现、NSS、防火墙和打印机驱动需验证 |
| `services/proxy` | N/B | Nix daemon 代理不迁；Docker、CLI 和需要代理的服务分别显式配置 |
| `services/scanning` | B/C | SANE 意图可迁；backend、udev 和设备权限按实际扫描仪配置 |
| `services/tailscale` | B/C | 服务可迁；认证状态不入库，需核对 OpenRC、路由和防火墙 |
| `services/usbmuxd` | B/C | 服务可迁；udev、配对状态和 iOS 设备实测 |

未启用的 Niri/Noctalia、Plasma 和 AMD 示例模块只能作为候选参考。尤其是仓库现有
`hardware/gpu/amd.nix` 只表达了“启用 graphics/amdgpu”的很小一部分，不能被误认为
完整的 Gentoo AMD GPU 方案。

## 6. Home Manager 模块逐项迁移判断

| 模块组 | 等级 | 结论 |
| --- | --- | --- |
| `core/session` | B | 保留 EDITOR/VISUAL/COLORTERM；删除 Nix profile 路径，重新定义登录会话环境 |
| `core/shell`、`cli/fish` | A/B | alias、函数可迁；Fish 路径和 `hmconfig` 名称需改 |
| `core/xdg` | A | XDG 目录约定可直接保留 |
| `cli/git`、`github`、`ssh` | A/C | 配置可迁；SSH 私钥不入库，macOS Tailscale 地址需核对 |
| `cli/prompt` | A/B | 保留 Starship preset；不再依赖 Nix build-time 生成 |
| `cli/terminal` | A/B | 工具清单可转为 world 需求；`nix-direnv` 只在继续使用 Nix 时保留 |
| `cli/alacritty`、`htop`、`glow`、`yazi`、`zellij` | A | 生成原生配置，核对版本和字体 |
| `cli/btop`、`lazygit` | A | 主要是安装意图，无复杂配置 |
| `development/emacs` | A/C | Elisp 高度可迁；包来源、tree-sitter grammar、PGTK、daemon/socket 需重做 |
| `development/tools` | B | Nix 专用工具在 Gentoo 主机配置仓库中可能仍有用，但不再是系统迁移必需品 |
| `development/codex`、`pi` | B/C | wrapper 可迁；CLI 安装来源、Node/npm 路径和 sandbox 能力需确认 |
| `desktop/apps` | B | 作为应用愿望清单；逐项决定 Portage、Flatpak 或上游包，不能假定同名 |
| `desktop/cursor` | A/B | 主题名和尺寸可迁；确保 GTK/XCursor/Sway 环境一致 |
| `desktop/fonts` | A/C | fontconfig 可迁；字体来源、授权、实际 family name 要逐项核对 |
| `desktop/fcitx5` | A/C | 用户配置可迁；插件、GTK/Qt 模块、Wayland 启动与 Emacs 输入需实测 |
| `desktop/lockscreen` | B/C | 锁屏参数可迁；systemd、suspend 顺序和随机壁纸脚本需改写 |
| `desktop/mime` | A/B | MIME 映射可迁；desktop file ID 按安装来源修正 |
| `desktop/mpv` | A/C | 配置可迁；Vulkan、AMDGPU 硬解后端需实测 |
| `desktop/obs` | B/C | 安装意图可迁；PipeWire portal 和插件打包需确认 |
| `desktop/sway` | A/C | 原生行为可迁；输出配置、脚本、绝对路径、用户服务和 portal 是重点 |
| `services/rclone` | B/C | remote/mount 意图可迁；配置与 token 私有，FUSE 卸载和用户监督需重做 |
| `secrets/sops`、`local-files` | B/C | sops/age 模型可保留；自动解密、权限、生命周期和 shell hook 需重做 |
| `communication/mail` | A/C | 账户和同步策略可迁；secret command、timer、证书和首次全量同步需验证 |

注意：仓库中还有 Ghostty、tmux、Helix 模块，但 workstation profile 当前没有启用；
它们应列入“候选配置”，不能当作当前桌面基线。Niri/Noctalia 和 Plasma 同理。

## 7. N 级：不应直接迁移的内容

### 7.1 NixOS/Home Manager 结构

- `flake.nix` 的 inputs、`nixosConfigurations` 和 Home Manager wiring；
- `system.stateVersion`、`home.stateVersion`；
- `mySystem.*.enable`、`myHome.*.enable` 模块开关和 assertion；
- `lib.mkIf`、`lib.mkDefault`、`pkgs.writeShellApplication` 等 Nix 组合方式；
- `/nix/store` 绝对路径和 `lib.getExe` 生成的路径；
- NixOS activation script、systemd unit 自动生成和 Nix generation 保留策略；
- `hardware-configuration.nix` 的 Nix 语法；
- Nix daemon 的代理和 GC（只有决定在 Gentoo 上继续安装 Nix 时才另行设计）；
- `NIXOS_OZONE_WL` 这类 NixOS 特有环境变量。

### 7.2 旧 Intel/NVIDIA 硬件策略

- `modules/system/hardware/cpu/intel.nix`
- `modules/system/hardware/gpu/nvidia-prime.nix`
- `modules/system/desktop/nvidia.nix`
- `modules/system/desktop/steam.nix` 中 NVIDIA offload 环境
- 旧 PCI bus ID、旧输出接线假设和 Intel/NVIDIA 分工说明

这些文件仍可用于理解旧机和完成数据导出，但不得成为 Gentoo AMD 目标配置的模板。

NixOS 配置仓库不应被直接改造成 `/etc` 的镜像。建议后续在此分支新增独立的
`gentoo/` 清单和 dotfiles 源文件，保持“可公开声明的配置”与“本机私有状态”分离。

## 8. 推荐的迁移顺序

1. **冻结旧机事实**：采集磁盘、数据、网络、服务、用户组、包和运行时版本清单。
2. **探测新 AMD 机器**：采集 CPU/GPU、PCI、磁盘、显示输出和固件信息，不复用旧 ID。
3. **建立可启动基座**：UEFI、内核/initramfs、fstab、AMD microcode、OpenRC、网络、SSH。
4. **完成 AMD 图形栈**：AMDGPU、Mesa、Vulkan、硬解、32 位游戏栈、休眠恢复。
5. **完成用户与音频**：PAM、elogind/seat、DBus、PipeWire、Bluetooth、Polkit。
6. **打通最小 Sway 会话**：greetd、Sway、终端、Fuzzel、portal、输入法、锁屏。
7. **迁移原生 dotfiles**：Sway、Emacs、Zellij、Fish、fontconfig、Fcitx、MIME。
8. **恢复系统服务**：打印/扫描、Docker、libvirt、Tailscale、usbmuxd、Flatpak。
9. **单独恢复 Mihomo**：先无订阅基线，再 secret、TUN、DNS 和代理联动。
10. **恢复有状态应用**：邮件、rclone、Jellyfin、Steam；逐项从加密备份恢复。
11. **对照验收后退役旧系统**：在完成备份恢复演练以前保留可启动的 NixOS。

## 9. 后续版本应补齐的产物

第一版之后，建议依次补充：

- 当前 NixOS 的“最终生效值”与运行时探测报告，而不仅是源代码静态盘点；
- 新 AMD 机器的硬件清单、内核配置需求和驱动验证；
- Nix 包名 → Gentoo atom/Flatpak/上游安装方式的映射表；
- OpenRC runlevel、依赖图和每个服务的 auto/manual 状态表；
- Sway 用户会话的进程树、环境传递和日志方案；
- `package.use`/license/keywords 的最小集合及选择理由；
- 公共配置与私有备份的完整文件清单；
- 分阶段验收表和回滚条件；
- 最终 Gentoo 配置目录结构。

## 10. 第一版验收结论

目前最容易保存的是用户层原生配置和配置数据；最需要精细设计的是：

1. OpenRC 下的用户图形会话与服务监督；
2. 新 AMD CPU/GPU 的内核、固件、Mesa/Vulkan、硬解和 32 位游戏栈；
3. Mihomo TUN/DNS 与 NetworkManager、Tailscale、Docker 的联动；
4. boot/initramfs/fstab/swap/zram/OOM 的显式实现；
5. sops、邮件、rclone 等 secret 与持久状态的安全恢复。

旧机的 Intel/NVIDIA 配置不再是迁移难点，因为目标方案明确不保留它。下一版硬件调查
应直接围绕新 AMD 平台进行；旧硬件配置只用于确保旧机在数据导出期间仍可正常使用。
