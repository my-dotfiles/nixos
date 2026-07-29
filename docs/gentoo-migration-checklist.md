# NixOS → Gentoo（OpenRC）迁移清单

> 审计日期：2026-07-29
> 状态：迁移前执行版
> 配置主源：`/home/yurikon/nixos-config` 的主开发分支（实际分支名为
> `master`，不是 `main`）
> 配置基线：`ecf1ba04655aad6f01f264c1aa2624a0bb17e1df`；审计时工作树干净
> 目标：Gentoo + OpenRC、全新 Bash 用户环境、优先恢复 Sway、Emacs 和系统服务
> 目标硬件：当前 Lenovo 本机，Intel i5-12500H + Iris Xe + NVIDIA RTX 2050
> 存储目标：512GB 盘承载新系统和新 home；2TB 盘在安装期间整盘保留，只选择性复用
> 旧数据
> 安装备份：`/run/media/yurikon/Momonga/MyData/Gentoo-Migration-20260729-final`

本文是迁移时逐项勾选的清单。旧迁移纲要中的 AMD 目标是假设草案，已经失效；实际安装
以 [gentoo-remote-reinstall-runbook.md](./gentoo-remote-reinstall-runbook.md) 第 10
章、本清单和迁移当天的最终审计结果为准。

## 0. 完成标准

只有同时满足下列条件，才能认为迁移完成：

- [ ] Momonga 上的安装必需备份通过 SHA-256 校验，敏感系统状态可用旧 home 中的
  age 私钥解密。
- [ ] 2TB 盘没有被格式化；两个 ext4 分区的 UUID、文件数量和抽样校验均正常。
- [ ] Gentoo 能在不挂载 2TB 盘时启动、登录 Bash、联网并进入最小 Sway 会话。
- [ ] 2TB 盘挂载后，选择的数据目录在新 home 下出现，UID/GID、ACL 和写权限正确。
- [ ] Sway 的终端、启动器、双屏/单屏、输入法、通知、状态栏、portal、锁屏和截图通过。
- [ ] Emacs PGTK、daemon、Org/Org-roam、中文输入、Tree-sitter、PDF、Mermaid 和 CTeX
  导出通过。
- [ ] Mihomo、Tailscale、SSH、PipeWire、打印/扫描、Docker、libvirt、Jellyfin、
  Flatpak、usbmuxd 按预期启动或保持手动启动。
- [ ] 邮件、rclone、浏览器、WeChat、Zotero、Steam 和游戏存档已恢复或明确放弃。
- [ ] 完成一次重启和一次 suspend/resume 验收。
- [ ] NixOS 根分区只在第 9 节的安装必需备份和恢复抽查完成后格式化。

## 1. 迁移前的已知事实

### 1.1 当前磁盘和数据量

| 当前设备 | UUID | 文件系统 | 当前用途 | 已用/总量 | 迁移动作 |
| --- | --- | --- | --- | --- | --- |
| 512GB 盘分区 1 | `B552-1C1F` | FAT32 | `/boot`，约 1GB | 约 176MB/1GB | 可继续作为 ESP；安装前备份 EFI 内容 |
| 512GB 盘分区 2 | `675b6f26-ba72-423c-8704-376ea011ed1c` | ext4 | NixOS `/` | 约 121GB/476GB | Gentoo 根分区候选；确认备份后才可格式化 |
| 2TB 盘分区 1 | `e6ea7aa4-834f-47c0-8843-8a4ff88d3a55` | ext4，label `home` | 旧 `/home` | 约 127GB/975GB | **保留，不格式化**；挂到隐藏基准点 |
| 2TB 盘分区 2 | `fef36a86-961e-4148-a2c6-6e56ec9a707f` | ext4 | `/data/media` | 约 699GB/889GB | **保留，不格式化**；继续作为媒体盘 |

当前 `~/` 约 111GB，其中主要空间为：

- `~/.local` 约 80GB，其中 Steam 约 75GB；
- `~/Learning` 约 6.7GB；
- `~/Documents` 约 4.2GB；
- `~/.cache` 约 3.7GB；
- `~/Pictures` 约 3.3GB；
- `~/Downloads` 约 3.0GB；
- `~/.var` 约 1.8GB；
- `~/Videos` 约 1.2GB；
- `~/Mail` 和 `~/.thunderbird` 各约 0.8GB。

本次安装已经明确保证 2TB KIOXIA 整盘不会被清理，因此不再把 old-home 和 media
复制到外置盘。外置盘 Momonga 是 exFAT，不能直接保存 Unix owner、ACL、xattr 和
符号链接；第 9 节将安装必需文件放进 tar，敏感系统状态再用 age 加密。tar 内部保留
元数据，exFAT 只承载归档文件。

### 1.2 用户和权限

- 当前用户：`yurikon`，UID `1000`，主 GID `100`（`users`）。
- 当前 home 权限：`0700`，所有者 `1000:100`。
- 当前附加组：`wheel`、`networkmanager`、`libvirtd`、`docker`。
- 旧 home 内绝大多数对象属于 `1000:100`。
- `/data/media` 同时存在 `956:956`、`1000:1000` 和 `1000:100`，不能假定
  Gentoo 的 Jellyfin UID/GID 与 NixOS 相同。
- 当前登录 shell 是 Fish；目标登录 shell 改为 `/bin/bash`。

### 1.3 当前运行基线

- NixOS：`26.11.20260723.e2587ca`，内核 `6.18.39`。
- 桌面：Wayland + Sway，greetd/tuigreet 登录。
- 当前源机器硬件：Intel i5-12500H、Intel Iris Xe、NVIDIA RTX 2050 PRIME。
- 当前内存约 16GiB；zram 约 3.8GiB，另有 `/home/.swapfile` 16GiB，
  `vm.swappiness=20`。
- 当前 Sway 同时使用 `DP-1` 和 `eDP-1`：
  - `DP-1`：2560×1440@165Hz，scale 1.25，逻辑位置 `0,0`；
  - `eDP-1`：2560×1600@120Hz，scale 1.6，逻辑位置 `2048,0`。
- 目标就是当前本机：Sway 和显示输出继续使用 Intel/i915，RTX 2050 只做 PRIME
  render offload；安装细节以执行手册第 10 章为准。

### 1.4 审计边界

普通用户已经完成配置仓库、home、运行服务、Docker、libvirt、Flatpak 和桌面状态审计。
下列 root-only 目录因 `sudo` 需要密码，尚未读取内部内容，必须在迁移前由 root
执行备份和清点：

- `/etc/NetworkManager/system-connections`
- `/etc/mihomo`、`/var/lib/private/mihomo`
- `/etc/ssh/ssh_host_*`
- `/var/lib/tailscale`
- `/var/lib/bluetooth`
- `/var/lib/lockdown`
- `/var/lib/jellyfin`
- `/var/lib/docker`
- `/var/lib/libvirt`
- `/etc/cups`、`/var/spool/cups`

不能因为这些目录当前体积不可见而跳过。

## 2. 512GB 新 home + 2TB 选择性复用方案

### 2.1 推荐布局

512GB 盘只需要一个 Gentoo 根文件系统。`/home/yurikon` 是该根文件系统上的普通目录，
不再单独分区：

```text
512GB root filesystem
├── /home/yurikon                  # 全新、干净、可独立登录
├── /swapfile                      # 如需要，放在本地根盘，不复用旧 /home/.swapfile
└── /mnt/storage/old-home          # 2TB 旧 home 分区的统一挂载点

2TB old-home filesystem
└── /mnt/storage/old-home/yurikon  # 原 NixOS home 内容，只选择性复用

2TB media filesystem
└── /data/media                    # movies/tv，保持独立挂载
```

关键原则：

- [ ] 不把 2TB 的旧 home 分区直接挂为 `/home`。
- [ ] 不整体复用旧 `~/.config`、`~/.local`、`~/.cache` 或 `~/.nix-profile`。
- [ ] 新 home 即使缺少 2TB 盘，也必须能登录、联网、使用 Bash、SSH、Sway 和 Emacs。
- [ ] 使用 UUID，而不是 `/dev/nvme*` 名称；换机器后设备枚举顺序可能改变。
- [ ] 先只读挂载并检查，再改为读写。

### 2.2 建议的目录归属

| 新 home 路径 | 建议位置 | 方法 | 原因 |
| --- | --- | --- | --- |
| `~/.ssh`、`~/.gnupg`、`~/.config/sops` | 512GB | 从加密备份复制 | 登录和解密不能依赖 2TB 盘；权限要求严格 |
| `~/.config` | 512GB | 全新生成，只复制选定状态 | 避免 Nix store 断链、旧桌面残留和版本冲突 |
| `~/.local/bin`、`~/.local/state` | 512GB | 全新生成，选择性恢复 | 包含脚本和程序状态，不应整体复用 |
| `~/.cache`、`~/.npm`、构建缓存 | 512GB | 重建 | 缓存不值得跨系统挂载 |
| `~/Downloads` | 512GB | 新目录 | 临时写入多，不应成为 2TB 依赖 |
| `~/Learning` | 2TB | bind mount 或软链接 | 约 6.7GB，含 Org 主库和项目 |
| `~/Documents` | 2TB | bind mount 或软链接 | 约 4.2GB，用户文档 |
| `~/Pictures` | 2TB | bind mount 或软链接 | 含壁纸和截图目录 |
| `~/Music`、`~/Videos` | 2TB | bind mount 或软链接 | 大型用户媒体 |
| `~/Mail` | 2TB 或 512GB | 优先 bind mount | Emacs 配置固定使用 `~/Mail`；保留 Maildir flags |
| `~/Zotero` | 2TB | bind mount | 文献附件库约 186MB |
| `~/.local/share/Steam` | 2TB | 单独 bind mount | 约 75GB；不要因此复用整个 `~/.local` |
| `~/.local/share/PrismLauncher` | 2TB | 单独 bind mount | 保留实例、存档和配置 |
| `~/.factorio`、`~/.config/StardewValley` | 512GB | 复制 | 存档不大，放本地更可靠 |
| WeChat、浏览器、Thunderbird 状态 | 512GB | 应用关闭后复制 | SQLite/登录数据库适合本地，不建议跨盘软链接 |
| `/data/media` | 2TB 第二分区 | 正常文件系统挂载 | Jellyfin 和本地播放器共同使用 |

bind mount 对应用完全表现为原路径，适合 Steam、Mail、Zotero 等固定路径。普通软链接
更容易维护，适合 `Learning`、`Documents`、`Pictures` 等人工访问目录。Flatpak
sandbox、文件选择 portal 或部分应用可能对软链接目标另行做权限判断；遇到这类目录时
优先改用 bind mount。

### 2.3 `fstab` 设计草案

以下只是目标结构示例，写入前必须用 Gentoo 实机的 `blkid` 再确认 UUID：

```fstab
UUID=e6ea7aa4-834f-47c0-8843-8a4ff88d3a55  /mnt/storage/old-home  ext4  rw,noatime,nofail  0  2
UUID=fef36a86-961e-4148-a2c6-6e56ec9a707f  /data/media            ext4  rw,noatime,nofail  0  2

/mnt/storage/old-home/yurikon/Learning                 /home/yurikon/Learning                 none  bind,nofail  0  0
/mnt/storage/old-home/yurikon/Documents                /home/yurikon/Documents                none  bind,nofail  0  0
/mnt/storage/old-home/yurikon/Pictures                 /home/yurikon/Pictures                 none  bind,nofail  0  0
/mnt/storage/old-home/yurikon/Mail                     /home/yurikon/Mail                     none  bind,nofail  0  0
/mnt/storage/old-home/yurikon/Zotero                   /home/yurikon/Zotero                   none  bind,nofail  0  0
/mnt/storage/old-home/yurikon/.local/share/Steam       /home/yurikon/.local/share/Steam       none  bind,nofail  0  0
/mnt/storage/old-home/yurikon/.local/share/PrismLauncher /home/yurikon/.local/share/PrismLauncher none bind,nofail 0 0
```

执行前：

- [ ] 在新 home 和旧盘上创建所有源、目标目录。
- [ ] 先执行 `mount /mnt/storage/old-home`，确认 `findmnt` 的来源确实是 2TB 分区。
- [ ] 再执行 `mount -a`；确认没有把空的本地挂载点误当作旧盘数据。
- [ ] 用 `findmnt -R /home/yurikon` 检查每个 bind mount。
- [ ] 用普通用户分别创建、重命名、删除一个测试文件。
- [ ] 重启后再次检查；不要只验证手工 `mount --bind`。

若 2TB 盘可能被拔除，建议把选择性挂载放进一个在 OpenRC `localmount` 之后运行的
本地服务：只有 `mountpoint -q /mnt/storage/old-home` 成功时才执行 bind mount，
否则记录警告并继续启动。不要让缺少数据盘导致无法进入救援 shell。

### 2.4 UID/GID 和服务权限

- [ ] Gentoo 创建 `yurikon` 时明确使用 UID `1000`。
- [ ] 优先继续使用主组 `users`，并确认其 GID 为 `100`；若不是，先设计组映射，
  不要直接对旧盘执行递归 `chown`。
- [ ] 新 home 保持 `0700`，私钥目录和文件分别保持 `0700`/`0600`。
- [ ] 按 Gentoo 实际包创建 `wheel`、音频、显卡、输入、Docker、libvirt 等附加组；
  不照抄 NixOS 的数字 GID。
- [ ] 为 `/data/media` 建立稳定的 `media` 共享组或 ACL，让 `yurikon` 可管理、
  Jellyfin 只获得所需的读/执行权限。
- [ ] 不把旧 UID `956` 直接当成 Gentoo Jellyfin 用户；安装后查询新服务 UID，再通过
  ACL 或共享组授权。
- [ ] 改权限前先生成 `getfacl -R` 备份和文件清单。

## 3. P0：必须保存且不可由重装恢复

### 3.1 配置仓库和工作树

`~/nixos-config` 当前没有 `main` 分支，主分支名是 `master`。截至本次复核，HEAD 与
`origin/master` 都在 `ecf1ba0`，工作树干净。该提交把此前 10 个文件中的迁移重点
正式纳入主分支：

- `flake.lock`
- `modules/home/cli/ssh.nix`
- `modules/home/desktop/niri.nix`
- `modules/home/desktop/plasma.nix`
- `modules/home/desktop/sway.nix`
- `modules/home/desktop/sway/config`
- `modules/home/development/emacs.nix`
- `modules/home/development/emacs/init.el`
- `modules/system/core/locale.nix`
- `modules/system/services/mihomo.nix`

其中必须保留的有效变化包括：

- Codeberg SSH identity 和直连规则；
- Sway docked 模式改为双屏同时启用；
- 跨输出聚焦、移动 workspace，以及按当前输出切换 workspace；
- 删除 `ctrl:nocaps`，保持标准 US 键盘布局；
- Emacs 加入 C/C++ Tree-sitter 构建工具和 XeLaTeX/CTeX 中文 Org 导出；
- Mihomo 对 Codeberg 直连。

迁移前仍要重新检查，因为审计后的任何修改都可能尚未提交：

- [ ] 记录最新 branch、HEAD、`git status --short` 和远端跟踪状态。
- [ ] 若届时有变化，提交它们，或至少保存 staged/unstaged binary patch。
- [ ] 创建包含所有 refs 的 Git bundle。
- [ ] 单独归档整个工作树，以覆盖未跟踪文件和 submodule/worktree 元数据。
- [ ] 同时保存 `/home/yurikon/nixos-to-gentoo`，包括未跟踪的迁移提纲 HTML。
- [ ] 保存 `/home/yurikon/nixos-config-macos`。

即使现在工作树干净，也不能把一次 `git clone` 当作完整备份：远端可能不可访问，
clone 不包含未来产生的未提交/未跟踪内容，也不包含本迁移仓库。

可在已确认的备份目录中保存三层副本：

```bash
git -C /home/yurikon/nixos-config status --short \
  > "$BACKUP_ROOT/nixos-config.status.txt"
git -C /home/yurikon/nixos-config diff --binary \
  > "$BACKUP_ROOT/nixos-config.worktree.patch"
git -C /home/yurikon/nixos-config bundle create \
  "$BACKUP_ROOT/nixos-config.bundle" --all
tar --acls --xattrs --numeric-owner -cpf \
  "$BACKUP_ROOT/nixos-config.worktree.tar" \
  -C /home/yurikon nixos-config
```

恢复演练应同时测试 bundle clone、patch apply 和 tar 内容；三者用途不同。

### 3.2 发现的其他有意义未提交工作

下列工作树存在未提交或未跟踪内容，必须逐个提交、打 patch 或完整归档：

- `~/Projects/demo/extract-and-translate-pdf`
- `~/Learning/org-learning`
- `~/Learning/projects/text-process-pipeline`
- `~/Learning/projects/cs3110-ocaml-nix`
- `~/Learning/projects/cpp-primer`
- `~/Learning/projects/typescript-learn`
- `~/playground/record-convert`
- `~/playground/agent`
- `~/Documents/thesis/thesis-project.dev`
- `~/worktrees/nixos-config-agent`
- `~/worktrees/tarot-cli`

`~/.local/state/noctalia`、`~/.local/share/Trash` 和生成站点中的缓存型工作树不应直接混入
代码备份；先判断它们是否只是缓存或回收站内容。

### 3.3 密钥、令牌和账户状态

全部使用加密备份，禁止放进 Git：

- [ ] `~/.ssh/`：至少包含 GitHub、Codeberg、GPU 主机等私钥、authorized_keys、
  known_hosts；恢复后检查目录 `0700`、私钥 `0600`。
- [ ] `~/.gnupg/`：密钥环和 trust DB；恢复权限并执行一次 `gpg --list-secret-keys`。
- [ ] `~/.config/sops/age/keys.txt`：sops 解密的唯一 age 私钥，当前为 `0600`。
- [ ] `~/nixos-config/secrets/user.yaml` 和 `.sops.yaml`：前者是加密 secret，
  后者记录 age recipient。
- [ ] `~/.config/rclone/rclone.conf`：Google Drive、OneDrive OAuth 状态，当前为 `0600`。
- [ ] `~/.config/gh/hosts.yml`：GitHub CLI 登录状态。
- [ ] `~/.local/share/keyrings`、`~/.local/share/kwalletd`、`~/.pki/nssdb`。
- [ ] `~/.codex/auth.json`、`config.toml`、history、SQLite 状态和 memories。
- [ ] `~/.pi/agent/auth.json`、settings 和有价值的 agent 状态。
- [ ] OBS profile/scenes；`service.json`、多路推流和 websocket 配置可能包含密钥，
  必须按 secret 处理。
- [ ] root-only 的 Mihomo 订阅 URL、Tailscale state、NetworkManager Wi-Fi secrets、
  Bluetooth/iOS pairing records。

不要备份 Home Manager 生成的
`~/.config/secrets/api-keys.{bash,fish}` 符号链接作为 secret 来源；真正的来源是
sops 加密文件和 age 私钥。Gentoo 上需要用 `umask 077` 把 secret 解密到
`XDG_RUNTIME_DIR` 或另一个仅用户可读的位置，再重新生成 Bash hook 和邮件的
`passwordCommand`。不要把 sops-nix 的 `/run/user/1000/secrets.d/...` 临时路径写死。

### 3.4 用户内容

- [ ] `~/Learning`，重点是 `~/Learning/org-learning`。
- [ ] `~/Documents`，包括论文、写作和微信文件。
- [ ] `~/Pictures`，包括 Sway 壁纸和 `Pictures/Screenshots`。
- [ ] `~/Music`、`~/Videos`、需要保留的 `~/Downloads`。
- [ ] `~/Projects`、`~/playground`、所有 Git worktree。
- [ ] `~/Zotero` 文献附件库。
- [ ] `~/Mail` Maildir；即使服务器可重新同步，也要保存本地 flags、草稿和未同步邮件。
- [ ] `~/.thunderbird` profile。
- [ ] `/data/media/movies` 和 `/data/media/tv` 保留在 2TB 原盘；本次不复制到
  Momonga，安装时用磁盘 by-id 和 UUID 双重保护。

### 3.5 输入法、剪贴板和桌面状态

- [ ] `~/.local/share/fcitx5/pinyin/user.dict`
- [ ] `~/.local/share/fcitx5/pinyin/user.history`
- [ ] `~/.local/share/fcitx5/rime/*.userdb`、`rime/user.yaml`
- [ ] `~/.local/share/cliphist-pins`；其中可能是敏感文本，必须加密备份。
- [ ] 如确实需要普通剪贴板历史，再保存 `~/.cache/cliphist`；否则安全删除并重建。
- [ ] `~/.config/obs-studio/basic/profiles`、`basic/scenes` 和所需 plugin config。
- [ ] `~/.config/zed`、VS Code/VSCodium 的 `User/` 配置和扩展清单。
- [ ] 浏览器 profile：`~/.config/mozilla/firefox`、`~/.config/BraveSoftware`、
  qutebrowser 数据；关闭浏览器后复制。

### 3.6 游戏和应用数据

- [ ] Steam `userdata`，当前约 6.5GB。
- [ ] Steam `steamapps/compatdata`，当前约 2.6GB；里面可能有未上云存档。
- [ ] Steam `steamapps/common`，当前约 58GB；可重下，但复用可显著缩短上手时间。
- [ ] Steam `appmanifest_*.acf`、workshop 和自定义 compatibility tools。
- [ ] `~/.factorio/saves`，当前约 12MB。
- [ ] `~/.config/StardewValley/Saves`，当前约 5.7MB。
- [ ] `~/.local/share/PrismLauncher/instances` 及 PrismLauncher 账户/全局配置。
- [ ] 其他游戏：`~/.local/share/SlayTheSpire2`、`~/.config/StardewValley` 等。
- [ ] Flatpak WeChat：
  `~/.var/app/com.tencent.WeChat`、`~/.xwechat`、`~/Documents/xwechat_files`。
- [ ] Spotify 仅在需要离线内容/登录连续性时保存
  `~/.var/app/com.spotify.Client`；缓存可重建。

## 4. Sway：必须完整迁移的桌面体验

### 4.1 原始配置源

优先从 `~/nixos-config` 提取，不要复制指向 `/nix/store` 的生成符号链接：

- [ ] `modules/home/desktop/sway/config`
- [ ] `modules/home/desktop/sway.nix`
- [ ] `modules/home/desktop/lockscreen.nix`
- [ ] `modules/home/desktop/fcitx5.nix`
- [ ] `modules/home/desktop/fonts.nix`
- [ ] `modules/home/desktop/mime.nix`
- [ ] `modules/system/desktop/sway.nix`
- [ ] `modules/system/desktop/thunar.nix`

需要从 Nix 模块拆成普通文件/脚本的内容：

- Sway 原生 config；
- Waybar JSON/CSS；
- Mako 配置；
- Kanshi profiles；
- Workstyle 映射；
- Wob 配置和 FIFO 启动脚本；
- networkmanager-dmenu 配置；
- 锁屏、截图、电源、蓝牙、音量/亮度、剪贴板 pin/unpin 脚本；
- Sway 会话 autostart/supervision 脚本；
- fontconfig、Fcitx5、MIME defaults。

### 4.2 必须保留的交互行为

- [ ] Mod4 作为主修饰键。
- [ ] 无平铺 gaps、平铺边框 0、浮动边框 2。
- [ ] `focus_follows_mouse no`、`mouse_warping output`。
- [ ] 当前双屏布局和 mobile 单屏 profile 作为行为参考。
- [ ] 当前工作区按输出切换：`next_on_output`/`prev_on_output`。
- [ ] Mod+Ctrl+方向键跨输出聚焦。
- [ ] Mod+Ctrl+Shift+方向键把整个 workspace 移到另一输出。
- [ ] Workstyle 动态改名后，数字 workspace 仍通过 `workspace number N` 操作。
- [ ] Fuzzel 应用启动器、Thunar 文件管理器、Alacritty 终端。
- [ ] Mako 通知、Waybar tray、网络/蓝牙/音频/电池/内存/时钟/电源模块。
- [ ] Fcitx5 拼音，自然码双拼，当前候选键、模糊音和主题。
- [ ] Cliphist 历史、固定剪贴板项和 Fuzzel 菜单。
- [ ] 区域、全屏、窗口和编辑截图；输出到 `~/Pictures/Screenshots` 并复制到剪贴板。
- [ ] 音量/亮度使用 Wob OSD。
- [ ] 5 分钟锁屏、10 分钟关闭输出、恢复时重新点亮、suspend 前锁屏。
- [ ] 当前键盘已移除 `ctrl:nocaps`；不要从旧提纲恢复 Caps→Ctrl 映射。
- [ ] Firefox Picture-in-Picture 和设置类窗口的 floating 规则。

### 4.3 必需软件和会话组件

最小集合：

```text
sway, XWayland, greetd/tuigreet, elogind/seat management, dbus
xdg-desktop-portal, xdg-desktop-portal-wlr, xdg-desktop-portal-gtk
polkit + graphical agent, gnome-keyring/PAM
PipeWire, WirePlumber, rtkit, pavucontrol
fcitx5 + GTK/Qt/Wayland/Chinese addons
waybar, mako, kanshi, workstyle, fuzzel
swaybg, swayidle, swaylock-effects
wl-clipboard, cliphist, wob
grim, slurp, swappy, jq
brightnessctl, playerctl
NetworkManager GUI/dmenu integration, Blueman
udisks2, udiskie, GVfs, Tumbler, Thunar
Alacritty, libnotify, xdg-utils
```

### 4.4 OpenRC 下必须重建的会话编排

NixOS 当前依赖 `sway-session.target` 和 systemd user units。Gentoo/OpenRC 不能复制这些
unit；必须建立等价的用户会话生命周期：

- [ ] greetd 通过 PAM 创建正确的 `XDG_RUNTIME_DIR`、DBus 和 elogind session。
- [ ] Sway 启动后再启动 Waybar、Mako、Kanshi、Workstyle、Fcitx5、swaybg、
  Cliphist watcher、Wob、Udiskie 和 Polkit agent。
- [ ] 所有进程以 `yurikon` 身份运行，并继承 `WAYLAND_DISPLAY`、`SWAYSOCK`、
  `DBUS_SESSION_BUS_ADDRESS`、locale、Fcitx 和 cursor 环境。
- [ ] 会话退出时清理这些进程，reload 时不重复启动。
- [ ] Wob 创建权限 `0600` 的 `${XDG_RUNTIME_DIR}/wob.sock` FIFO，再把 FIFO
  作为 wob stdin；不能照搬 systemd socket activation。
- [ ] Emacs、mbsync、rclone 不绑死在 Sway 生命周期。
- [ ] portal 只启动一套正确后端；用 Firefox/OBS/Flatpak 实测文件选择和屏幕共享。

Nix 注入值必须替换：

- `@terminal@`：不能再使用 `systemd-run --user --scope --slice=app.slice`；
  改为普通 Alacritty 启动 wrapper。
- `@menu@`：保留 Fuzzel，但移除 systemd-run launch prefix。
- `@home@`：替换为新 home。
- `/run/current-system/sw/bin/fcitx5`：替换为 Gentoo 的 `fcitx5` 路径。
- `NIXOS_OZONE_WL`：删除；保留通用 Wayland 环境变量。
- 所有 `/nix/store/...` 可执行文件路径：改成 PATH 查找或目标脚本变量。

### 4.5 目标硬件适配

- [ ] 在 Gentoo Sway 内重新运行 `swaymsg -t get_outputs` 和 `get_inputs`。
- [ ] 用稳定 PCI symlink 把 Sway 固定到 Intel `0000:00:02.0`，不写死 `card0/1`。
- [ ] NVIDIA PRIME 变量只放在 `prime-run` 中，不全局导出。
- [ ] 默认 Mesa renderer 是 Intel；`prime-run` renderer 是 RTX 2050。
- [ ] RTX 2050 空闲时能进入 Runtime D3，不启用 `nvidia-persistenced`。
- [ ] 根据新输出名重写 Sway 和 Kanshi；不能假定仍叫 `DP-1`/`eDP-1`。
- [ ] 验证 scale 1.25/1.6 下 GTK、Qt、XWayland、Fcitx 候选窗和 cursor 大小。
- [ ] 验证外屏插拔、workspace 迁移、lid close、suspend/resume。
- [ ] 验证 Vulkan、VA-API、OBS PipeWire capture 和 Steam 32 位图形栈。

## 5. Emacs：必须恢复的编辑和知识工作流

### 5.1 配置与数据

- [ ] 复制 `modules/home/development/emacs/init.el` 为普通
  `~/.emacs.d/init.el`。
- [ ] 复制 `early-init.el`。
- [ ] 保留兼容 loader `~/.emacs`，或确认 Gentoo Emacs 直接加载 init。
- [ ] 将 `@mmdc@`、`@wl-copy@` 替换为 Gentoo 可执行路径或普通命令名。
- [ ] 保留 `~/Learning/org-learning`，这是 `org-directory` 和
  `org-roam-directory`。
- [ ] 保留 `00-quick`、Org 源文件、附件和 `.git`。
- [ ] `org-roam.db` 可以重建，但源 Org 文件不可丢失。
- [ ] 选择性恢复 `.emacs.d/custom.el`、bookmarks、history、places、projects、
  recentf、`.org-id-locations`、eshell history。
- [ ] 不需要迁移 `eln-cache`、旧 ELPA backup、Tree-sitter 编译缓存和 auto-save 列表，
  除非其中有尚未恢复的编辑内容。

### 5.2 Emacs 构建能力

目标 Emacs 应提供：

- [ ] PGTK/原生 Wayland GUI。
- [ ] native compilation。
- [ ] Tree-sitter。
- [ ] SQLite。
- [ ] TLS、JSON、XML、image/PDF 所需支持。
- [ ] Fcitx5 在 PGTK 下可正常输入中文。

当前 Emacs daemon 特意清空 `GTK_IM_MODULE`，同时保留 `QT_IM_MODULE=fcitx`、
`XMODIFIERS=@im=fcitx`、`INPUT_METHOD=fcitx`、`SDL_IM_MODULE=fcitx`。迁移后必须分别
测试 daemon GUI frame 和 `emacs -Q`，避免 GTK IM 与 Wayland text-input 重复提交。

### 5.3 Elisp 包和外部工具

必须恢复的包组：

- completion/navigation：Consult、Corfu、Vertico、Marginalia、Orderless、
  Embark/Embark Consult、Ace Window、Avy；
- Git/help/env：Magit、Helpful、Envrc、Multiple Cursors；
- snippet：Tempel、Tempel Collection、Eglot Tempel；
- language：Markdown、Nix、Haskell、Tuareg/OCaml Eglot、YAML、Mermaid；
- Org：Org-roam、Org MIME、HTMLize；
- UI：Modus/EF/Gruvbox themes、Ligature、Nerd Icons 系列；
- document/mail：PDF Tools、mu4e。

Tree-sitter grammars：

```text
bash, c, c-sharp, cmake, cpp, css, dockerfile, doxygen, go, gomod,
html, haskell, java, javascript, json, mermaid, python, ruby, rust,
toml, tsx, typescript, yaml
```

外部工具：

```text
ripgrep, fd, sqlite, wl-copy
mermaid-cli/mmdc
nixd, nixfmt, markdown-oxide, yaml-language-server, basedpyright
compiler toolchain for missing grammar builds
mu, isync/mbsync, msmtp, w3m
TeX Live + ctex + fandol + latexmk + XeTeX
```

项目专属 Haskell、CMake、OCaml 等 language server 继续由项目环境提供，不需要全部变成
Gentoo 全局包。

### 5.4 daemon 和验收

- [ ] OpenRC 下用用户级 supervisor、登录脚本或桌面 autostart 启动
  `emacs --daemon`；不强求复刻 socket activation。
- [ ] `EDITOR`、`VISUAL` 指向 `emacsclient -t -a emacs`。
- [ ] Bash alias `e`、`et` 可分别打开 GUI/TTY client。
- [ ] 新建 GUI frame，检查字体：JetBrainsMono Nerd Font Mono 13pt，
  CJK fallback 为 Maple Mono NF CN。
- [ ] 打开 Org-roam，重建 DB，并测试 capture/find/insert。
- [ ] 导出一个含中文的 Org 文件为 PDF，确认 CTeX/XeLaTeX/字体齐全。
- [ ] 编译 Mermaid，打开 PDF Tools，测试 Eglot 和 envrc。
- [ ] 打开 mu4e，索引和发送一封测试邮件。

## 6. Bash：替代 Fish 的目标配置

Fish 不作为 Gentoo 目标配置迁移。只提取仍有价值的行为：

- [ ] `/etc/passwd` 中 `yurikon` 的 shell 是 `/bin/bash`。
- [ ] `~/.bash_profile` source `~/.bashrc`，图形登录和 TTY 登录行为一致。
- [ ] PATH 只保留通用目录：
  `~/.local/bin`、`~/.cargo/bin`、`~/.npm-global/bin`；默认删除
  `~/.nix-profile/bin` 和 `~/.local/state/nix/profile/bin`。
- [ ] 环境变量：
  `EDITOR`、`VISUAL`、`COLORTERM=truecolor`、`HERMES_TUI=1`。
- [ ] aliases：`ls/ll/la`→eza、`cat`→bat、`g`→git、`e/et`→emacsclient，
  `..`、`...`、`c` 和 Bash reload。
- [ ] 将 Fish 的 Yazi cwd wrapper 改写为 Bash 函数 `y()`。
- [ ] 初始化 Starship、Zoxide、Fzf 和 Direnv 的 Bash hook。
- [ ] source `~/.config/secrets/api-keys.bash`，但只在文件可读时执行。
- [ ] 保留 Git 配置、gh SSH 协议、SSH host rules。
- [ ] 根据实际仓库路径把 `hmconfig` 改名为更通用的 `sysconfig` 或删除。
- [ ] 确认脚本 shebang 使用 Bash 时目标系统已安装 Bash；普通 POSIX 脚本尽量改 `/bin/sh`。

目标 `.bashrc` 不应 source Fish 文件，也不应依赖 Home Manager 生成的
`hm-session-vars.sh`。

## 7. 系统服务迁移矩阵

| 服务 | 当前事实 | 必须保存/重建 | 目标启动策略 | 验收 |
| --- | --- | --- | --- | --- |
| NetworkManager | enabled/active | root-only connection profiles；DNS 所有权；关闭严格 rp-filter 的意图 | OpenRC default | 有线、Wi-Fi、休眠恢复；不泄露 DNS |
| Mihomo | enabled/active，TUN gVisor，7890/9090 | `/etc/mihomo/config.yaml`、订阅、provider、选择状态；CLI 脚本 | 网络后自动；失败重启 | TUN、fake-IP、IPv4/6、CN/private/Codeberg 直连、控制台 |
| SSH server | enabled/active | 决定是否保留 host keys；sshd_config、防火墙 | default | 本地和 Tailscale 远程登录；禁止意外密码暴露 |
| Tailscale | enabled/active | `/var/lib/tailscale` 或重新认证；路由/firewall | default | 节点身份、peer 连接、与 Mihomo 共存 |
| PipeWire | active | ALSA、Pulse 兼容、WirePlumber、rtkit、32 位 | 用户会话 | 扬声器、耳机、麦克风、HDMI、Steam、OBS |
| Bluetooth | active | `/var/lib/bluetooth` 配对状态或重新配对 | default + 用户 agent | 音频/鼠标/键盘、Blueman、Waybar |
| CUPS/Avahi | active；当前无打印队列、无默认打印机 | 服务和 mDNS；打印机可重新添加 | 按需或 default | 发现和打印测试页 |
| SANE | 已配置 | backend、udev、scanner group | 按需 | Simple Scan 实扫一页 |
| UDisks/GVfs | active | Polkit、FUSE、Udiskie、Tumbler | system + Sway session | U 盘自动挂载、缩略图和安全卸载 |
| Docker | 当前 active，但设计为不自启 | 当前无 container/volume；只有 Ubuntu 和 tinymediamanager 镜像，可重拉 | **手动** | 手动启动、Compose、代理、weekly prune |
| libvirt | enabled/active | 当前无 VM、pool、network；无需迁移镜像 | 可 default 或手动 | KVM、virt-manager、默认网络按需重建 |
| Flatpak | system Flathub | app list；用户 app data | 无常驻 daemon | 恢复 WeChat、Spotify，portal 正常 |
| Jellyfin | 安装但 inactive/不自启 | `/var/lib/jellyfin`；媒体权限；数据库版本 | **手动** | 库、用户、海报、播放、硬解、端口 |
| usbmuxd | active | `/var/lib/lockdown` 或重新 pairing | default/按需 | iPhone/iPad 识别和信任 |
| power | UPower + power-profiles-daemon + logind policy | lid、电源键、低电量阈值 | default | docked lid ignore、移动时 suspend、低电量动作 |
| rclone | gdrive/onedrive 定义，默认不启动 | `rclone.conf` 和 OAuth token | **手动用户服务** | mount、读写、卸载、断网不阻塞登录 |
| mbsync | 10 分钟 user timer | 4 个账户策略和 sops secret | 用户 cron/supervisor | 无并发同步、完成后 `mu index` |
| Emacs daemon | user socket activation | 配置和启动环境 | 用户登录后启动 | `emacsclient` 自动可用 |

### 7.1 Mihomo 特别检查

- [ ] mixed port `7890`，controller 仅监听 `127.0.0.1:9090`。
- [ ] TUN、auto-route、auto-detect-interface、DNS hijack。
- [ ] fake-IP range、DoH nameserver、GeoIP/GeoSite。
- [ ] subscription provider 每小时更新，健康检查 300 秒。
- [ ] private/CN/局域网/Tailscale/Codeberg 直连。
- [ ] OpenRC init script 使用正确 capability/TUN 权限、pid/supervision 和日志。
- [ ] `mihomoctl` 的 `systemctl`/`journalctl` 全部替换为 OpenRC 和目标日志命令。
- [ ] Docker、Codex、Pi 的代理 wrapper 仍指向本机 7890。
- [ ] 订阅 URL 永不进入 Git 或普通日志。

### 7.2 当前无须复制的大型服务状态

- Docker API 检测到 0 container、0 volume，只有两个可重拉镜像。
- libvirt 检测到 0 VM、0 storage pool、0 virtual network。
- CUPS 当前没有打印队列和默认打印机。

仍应在 root 最终审计中复核一次；若迁移前新增了 container、volume 或 VM，以迁移当天
状态为准。

## 8. 软件恢复顺序

### 8.1 第一批：登录和救援能力

- [ ] Bash、coreutils、sudo、OpenSSH、Git/Git LFS。
- [ ] NetworkManager、iproute2、curl、wget、rsync。
- [ ] vim 或其他救援编辑器。
- [ ] pciutils、usbutils、parted、e2fsprogs、dosfstools、smart/nvme 工具。
- [ ] sops、age、GPG。

### 8.2 第二批：快速进入 Sway

- [ ] 第 4 节的 Sway 最小集合。
- [ ] Firefox、Alacritty、Thunar。
- [ ] Fcitx5 和字体。
- [ ] PipeWire/WirePlumber。
- [ ] Flatpak/portal。

### 8.3 第三批：CLI 和开发体验

```text
ripgrep fd bat eza fzf jq fastfetch tree unzip file
curl wget rsync aria2 ncdu dust tokei cloc mdcat
pandoc mermaid-cli
git gh lazygit btop htop yazi zellij glow
starship zoxide direnv shellcheck shfmt
nodejs npm bubblewrap socat
```

当前 npm global 包：

- `@openai/codex@0.145.0`
- `@earendil-works/pi-coding-agent@0.80.10`
- `npm@11.17.0`

恢复时应重新安装包，只选择性恢复 auth/config/state；不要把旧
`~/.npm-global/lib/node_modules` 当作唯一安装方式。

### 8.4 第四批：桌面应用

```text
LibreOffice, imv, MediaElch, qutebrowser, Simple Scan, Thunderbird,
VS Code/VSCodium, Zed, Xarchiver, Zathura, Zotero,
PrismLauncher, Faugus Launcher, OBS, mpv, Steam, Protontricks
```

Flatpak 当前安装：

- `com.tencent.WeChat`
- `com.spotify.Client`

当前 profile 未启用 Ghostty、Tmux、Helix、Niri 和 Plasma；它们是候选配置，不属于
恢复 Sway 基线的阻塞项。MIME 配置当前却指向 `Helix.desktop`，迁移到 Bash/Emacs
方案时应把文本、Markdown、JSON、YAML 默认编辑器改成实际安装的 Emacs desktop ID。

### 8.5 邮件和 rclone 的快速恢复细节

邮件：

- [ ] Maildir base 保持 `~/Mail`。
- [ ] Gmail 是 primary，IMAP/SMTP 和全部文件夹双向同步。
- [ ] iCloud 同步 Inbox、Archive、Deleted Messages、Drafts、Junk、Sent Messages。
- [ ] QQ 同步常用文件夹并排除“其他文件夹”。
- [ ] 163 当前只用于 SMTP/mu4e context，mbsync 因服务端 SELECT 问题保持关闭。
- [ ] 四个账户密码继续来自外部 secret command，不写入 `.mbsyncrc`/`.msmtprc`。
- [ ] 每 10 分钟运行一次 `mbsync -a`，使用 `flock` 防止重入，成功后执行 `mu index`。

rclone：

- [ ] `gdrive:` 挂载到 `~/cloud/gdrive`。
- [ ] `onedrive:` 挂载到 `~/cloud/onedrive`。
- [ ] 保持默认不自动启动，避免远端不可用时文件管理器卡住。
- [ ] 保留 `--vfs-cache-mode writes`、72 小时目录缓存、1 分钟 poll 和较短 timeout。
- [ ] 为启动、状态和 `fusermount3 -uz` 卸载提供 Bash 脚本或用户 supervisor entry。

## 9. 备份执行清单

### 9.1 本次范围

安装时只格式化 512GB Micron 的 root 分区。2TB KIOXIA 的 old-home 和 media 两个
ext4 分区均完整保留，因此本次 Momonga 备份只包含：

- 三个配置仓库的完整工作树、`.git`、bundle、HEAD、status 和 binary patch；
- ESP；
- NetworkManager、Mihomo、SSH host key、Tailscale、Bluetooth/iOS pairing、
  Jellyfin 和 CUPS 等位于 512GB 上的 root-only 状态；
- 磁盘、挂载、硬件、网络、服务和 Flatpak 清单；
- 本清单与远程重装手册的离线副本。

本次明确不复制：

- 2TB old-home 中的 `Learning`、`Documents`、`Pictures`、`Mail`、Steam、
  浏览器、密钥和其他用户数据；
- 2TB media 分区；
- `/nix/store`、缓存、Docker 镜像和空的 libvirt runtime。

Momonga 的 UUID 必须为 `EB7F-5025`，目标目录固定为：

```text
/run/media/yurikon/Momonga/MyData/Gentoo-Migration-20260729-final
```

本次执行记录：目标约 304MB、38 个普通文件；`SHA256SUMS` 覆盖其余 37 个文件且
全部通过。三个 bundle 均记录完整历史且可以 clone，工作树 tar 包含本清单和备份脚本，
`system-state.tar.age` 已实际解密并确认包含 ESP、NetworkManager、Mihomo、SSH 和
Tailscale。`/etc/jellyfin` 未安装，其余第 9.3 节要求的 root-only 路径均已收入归档。

### 9.2 在旧 NixOS 上执行

1. 保持 2TB 两个分区和 Momonga 都已挂载。不要关闭网络、SSH 或桌面应用；这些应用
   的用户状态留在不会格式化的 2TB 上。
2. 查看目标身份和可用空间：

   ```bash
   findmnt -T /run/media/yurikon/Momonga -o SOURCE,FSTYPE,UUID,OPTIONS
   df -h /run/media/yurikon/Momonga
   ```

   只有看到 `exfat` 和 UUID `EB7F-5025` 才继续。
3. 确认目标目录尚不存在：

   ```bash
   test ! -e \
     /run/media/yurikon/Momonga/MyData/Gentoo-Migration-20260729-final
   ```

4. 从本仓库运行备份脚本：

   ```bash
   cd /home/yurikon/nixos-to-gentoo
   ./scripts/backup-gentoo-migration.sh
   ```

5. 出现 Polkit 授权窗口时输入本机管理员密码。该步骤只读取 `/boot`、`/etc` 和
   `/var` 的选定目录；它不会写 512GB/2TB 内置盘，也不会执行 `--delete`。
6. 等待脚本打印 `Backup completed`。脚本会先验证 Momonga 的 UUID/文件系统，
   拒绝覆盖同名目录；敏感系统状态保存为
   `archives/system-state.tar.age`。

若脚本因目标目录已存在而停止，不要删除或覆盖旧目录。给新一轮备份传入另一个以
`Gentoo-Migration-` 开头的目录，例如：

```bash
./scripts/backup-gentoo-migration.sh \
  /run/media/yurikon/Momonga/MyData/Gentoo-Migration-20260729-retry
```

### 9.3 校验和恢复抽查

1. 完整校验所有归档：

   ```bash
   BACKUP_ROOT=/run/media/yurikon/Momonga/MyData/Gentoo-Migration-20260729-final
   cd "$BACKUP_ROOT"
   sha256sum --check SHA256SUMS
   ```

2. 确认仓库 bundle 可以读取，并把迁移仓库临时 clone 到 `/tmp`：

   ```bash
   VERIFY_REPO=$(mktemp -d)
   git -C "$VERIFY_REPO" init -q
   git -C "$VERIFY_REPO" bundle verify \
     "$BACKUP_ROOT/repositories/nixos-config.bundle"
   git -C "$VERIFY_REPO" bundle verify \
     "$BACKUP_ROOT/repositories/nixos-to-gentoo.bundle"
   git -C "$VERIFY_REPO" bundle verify \
     "$BACKUP_ROOT/repositories/nixos-config-macos.bundle"
   RESTORE_TEST=$(mktemp -d)
   git clone "$BACKUP_ROOT/repositories/nixos-to-gentoo.bundle" \
     "$RESTORE_TEST/nixos-to-gentoo"
   git -C "$RESTORE_TEST/nixos-to-gentoo" fsck --full
   ```

3. 确认 tar 可读取且包含三个工作树：

   ```bash
   tar -tf "$BACKUP_ROOT/archives/config-repositories.tar" \
     | sed -n '1,20p'
   ```

4. 用仍在 2TB old-home 中的 age 私钥检查加密归档。此命令只列目录，不写恢复文件：

   ```bash
   age -d -i /home/yurikon/.config/sops/age/keys.txt \
     "$BACKUP_ROOT/archives/system-state.tar.age" \
     | tar -tf - \
     | sed -n '1,40p'
   ```

5. 核对 `inventory/system-state-paths.txt`。必须至少显示 `/boot`、
   `/etc/NetworkManager`、`/etc/mihomo`、`/etc/ssh` 和 `/var/lib/tailscale`
   为 `included`；确实未安装的状态可显示 `missing`。
6. 执行 `sync`，然后正常弹出 Momonga。不要在校验前格式化 512GB。

### 9.4 进入 Live 环境后的最后门槛

1. 只读挂载 Momonga，重新执行 `sha256sum --check SHA256SUMS`。
2. 保存 Live 环境看到的 `lsblk` 和两个内置盘的分区表到同一备份目录。
3. 对照第 0.3 节的 by-id、型号、容量和 UUID。
4. 只允许格式化 Micron
   `...220434EACA5D-part2`；KIOXIA `...2FCKS0F5Z0E8` 的整盘和两个分区都不得
   出现在任何 `mkfs` 命令中。

## 10. Gentoo 安装与恢复顺序

### 阶段 A：冻结和保护磁盘

- [ ] 打印或离线保存本清单。
- [ ] 完成第 9 节的 Momonga 备份、SHA-256 校验、bundle clone 和 age 解密抽查。
- [ ] 物理确认 512GB 与 2TB 盘的型号、容量和 UUID。
- [ ] Gentoo 安装期间不格式化 UUID 为 `e6ea...` 和 `fef3...` 的两个分区。
- [ ] 如条件允许，安装/分区 512GB 时临时断开 2TB 盘。

### 阶段 B：最小 Gentoo

- [ ] 512GB 根分区、ESP、bootloader、内核/initramfs。
- [ ] 安装 Intel microcode、i915/Mesa、SOF firmware 和
  `nvidia-drivers[kernel-open]`；不混入 AMD 图形配置。
- [ ] Sway 只使用 Intel，NVIDIA 只做 PRIME offload，并保留独显 Runtime D3。
- [ ] OpenRC、udev、DBus、elogind/seat、NetworkManager、SSH。
- [ ] 创建 UID 1000 的 Bash 用户和本地新 home。
- [ ] 创建本地 swapfile/zram/OOM 策略；不复用 2TB 旧 `/home/.swapfile`。
- [ ] 重启到 Gentoo，只用 TTY 完成网络和 SSH 验收。

### 阶段 C：挂载 2TB

- [ ] 首次只读挂载旧 home 和 media。
- [ ] 核对 UUID、文件数量、owner 分布、抽样 checksum。
- [ ] 改为读写，建立第 2 节的选择性 bind mounts/links。
- [ ] 调整 UID/GID/ACL，只改必要目录。
- [ ] 重启并验证 2TB 缺失时仍能登录。

### 阶段 D：Sway 最小闭环

- [ ] GPU/DRM、seat、greetd、Sway、Alacritty、Fuzzel。
- [ ] DBus、Polkit、portal、PipeWire。
- [ ] Waybar/Mako/Kanshi/Fcitx5/lockscreen。
- [ ] 截图、剪贴板、Wob、Udiskie、Thunar。
- [ ] 双屏、单屏、suspend/resume。

### 阶段 E：Emacs 和 Bash

- [ ] 恢复 Bash 配置、SSH、Git、sops。
- [ ] 安装 Emacs 能力和包。
- [ ] 恢复 Org、daemon、CTeX、Mermaid、PDF、mu4e。
- [ ] 恢复 Codex/Pi wrapper 和 npm 包。

### 阶段 F：服务和应用

- [ ] Mihomo → Tailscale → Docker/libvirt。
- [ ] CUPS/Avahi/SANE、Bluetooth、usbmuxd。
- [ ] Flatpak、WeChat、Spotify。
- [ ] Jellyfin 和 `/data/media` 权限。
- [ ] 邮件、rclone。
- [ ] Steam、PrismLauncher、游戏存档。

## 11. 最终验收表

### 启动和存储

- [ ] bootloader 中 Gentoo 和回退入口均有效。
- [ ] `mount -a` 无错误。
- [ ] 新 home 确实位于 512GB 根文件系统。
- [ ] `Learning/Documents/Pictures/Mail/Steam` 的实际来源与设计一致。
- [ ] 2TB 盘缺失时不会阻止启动或 Bash 登录。
- [ ] swap/zram priority、swappiness 和 OOM 策略符合目标内存。

### Sway

- [ ] greetd 登录和退出正常，没有重复用户服务。
- [ ] Waybar、Mako、Kanshi、Workstyle、Fcitx5、Wob 全部运行。
- [ ] 双屏/单屏切换和跨输出 workspace 快捷键正常。
- [ ] 音频、亮度、蓝牙、网络、托盘、锁屏、截图正常。
- [ ] Firefox/OBS/Flatpak portal 和屏幕共享正常。

### Emacs/Bash

- [ ] Bash 登录、PATH、aliases、Yazi wrapper、Starship/Zoxide/Direnv 正常。
- [ ] `emacsclient`、中文输入、字体、Org-roam、Mermaid、PDF、CTeX 正常。
- [ ] mu4e 同步/索引/发送正常。
- [ ] sops 只在需要时解密，secret 文件权限正确。

### 服务

- [ ] `rc-status` 与第 7 节自动/手动策略一致。
- [ ] Mihomo/Tailscale/DNS/IPv6/局域网直连正常。
- [ ] Docker 和 Jellyfin 没有被错误加入自动启动。
- [ ] rclone 断网时不阻塞登录或文件管理器。
- [ ] Jellyfin 可读 media，普通用户仍能管理媒体文件。

### 数据

- [ ] Git dirty work 已恢复。
- [ ] SSH/GPG/age/rclone/gh 认证正常。
- [ ] Org、论文、Zotero、Mail、Thunderbird、WeChat 数据可读。
- [ ] Steam 云存档和至少一个本地存档可用。
- [ ] Momonga 安装备份仍保留，不因首次成功启动而立即删除。

## 12. 明确不直接迁移的内容

- `/nix/store`、NixOS generations、Home Manager profile 和 Nix eval cache。
- 指向 `/nix/store` 的生成 symlink；改从 `~/nixos-config` 提取普通文件。
- 整个旧 `~/.config`、`~/.local`、`~/.cache`。
- Fish 登录 shell和 Fish-only hook。
- NixOS 的 `system.stateVersion`、`home.stateVersion`、module option 和 activation script。
- systemd system/user unit 本身；只迁移其行为、依赖和启动策略。
- `NIXOS_OZONE_WL`、`/run/current-system/sw` 和其他 NixOS 路径。
- 缓存：Nix、fontconfig、thumbnail、shader、Puppeteer、ELN、Tree-sitter build cache。
- Steam shader cache；可重建。
- Docker 的两个镜像和空 runtime state；可重新拉取。
- libvirt 的空 runtime state。
- Niri/Noctalia、Plasma 等未启用桌面，除非迁移后另行决定。

最重要的边界是：2TB 盘保存的是数据，不是 Gentoo 的配置管理方案。Gentoo 新 home
应先独立、干净、可启动，再把经过选择的旧数据接回去。
