# NixOS → Gentoo（OpenRC）远程重装执行手册

> 版本：2026-07-29
>
> 用途：在尽量少翻阅 Gentoo Handbook 的情况下，完成本机重装和工作环境恢复。
>
> 配套审计：[gentoo-migration-checklist.md](./gentoo-migration-checklist.md)
>
> 配置参考：`/home/yurikon/nixos-config` 的 `master` 分支、提交
> `ecf1ba04655aad6f01f264c1aa2624a0bb17e1df`；审计时工作树干净。

## 0. 先读结论

### 0.1 到哪一步可以改用 SSH

只有以下动作必须在目标机器前完成：

1. 用 UEFI 模式启动官方 Gentoo Minimal Install ISO。
2. 接通有线网络，确认机器获得 IP。
3. 把自己的 SSH 公钥放入 Live 环境的 `/root/.ssh/authorized_keys`。
4. 启动 Live 环境的 `sshd`。
5. 从另一台机器成功登录两次，并进入 `screen`。

完成本手册的 **检查点 SSH-LIVE** 后，即可在 SSH 中完成格式化、Stage 3、chroot、
内核、引导器和基本系统安装。不要等到 Gentoo 安装完才开 SSH。

第一次重启时 Live SSH 会断开。新 Gentoo 会使用另一套 SSH host key，这是正常现象。
完成 **检查点 SSH-INSTALLED** 后，后续 Sway、Emacs、Mihomo 和数据恢复都从新系统的
SSH 中完成。

### 0.2 推荐安装路线

本手册采用以下确定方案：

- init：OpenRC。
- Stage 3：amd64、OpenRC、glibc、multilib；Steam/32 位图形栈需要 multilib。
- 内核：先用 `sys-kernel/gentoo-kernel-bin`，稳定后再考虑自编译。
- 引导：沿用现有 1 GiB ESP 和 systemd-boot；这不意味着使用 systemd init。
- 根文件系统：格式化 512GB Micron 盘的第二分区为 ext4。
- 新 home：`/home/yurikon` 是 512GB 根文件系统上的普通目录，不单独分区。
- 2TB KIOXIA 盘：两个分区均不格式化；先挂到固定基准点，再选择性 bind mount。
- 登录 shell：Bash；不恢复 Fish 的登录 shell、插件和 Fish 私有状态。
- 桌面：先恢复最小 Sway，再恢复 Waybar、Mako、输入法、锁屏和其他组件。
- 网络：直连可用就直连；否则优先国内 Gentoo 镜像；仍不可用时使用离线携带的
  Mihomo 临时配置。
- 目标硬件：就是当前这台机器，固定为 Intel Core i5-12500H、Intel Iris Xe 核显和
  NVIDIA GeForce RTX 2050 独显；第 10 章是权威安装分支。
- 图形拓扑：Sway 和全部显示输出走 Intel/i915，RTX 2050 只为游戏和计算做
  PRIME render offload；不把 NVIDIA 设为桌面主 GPU。

### 0.3 本手册中的危险目标

当前机器已经核实的磁盘身份如下：

| 角色 | 稳定设备路径 | 当前内容 | 动作 |
| --- | --- | --- | --- |
| 512GB 整盘 | `/dev/disk/by-id/nvme-Micron_MTFDKBA512TFH_220434EACA5D` | NixOS | 只重用现有分区表 |
| ESP | 上述路径加 `-part1` | FAT32，UUID `B552-1C1F` | 保留、不格式化 |
| Gentoo 根候选 | 上述路径加 `-part2` | ext4，UUID `675b...ed1c` | **将被格式化** |
| 2TB 整盘 | `/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G3_SSD_2FCKS0F5Z0E8` | home + media | **整盘保留** |
| 旧 home | 上述路径加 `-part1` | ext4，UUID `e6ea...3a55` | 保留 |
| media | 上述路径加 `-part2` | ext4，UUID `fef3...707f` | 保留 |

如果 Live 环境中任意型号、序列号、容量或分区结构不同，停止执行格式化命令。

## 1. 命令约定与远程安装纪律

- `live #`：Gentoo Live 环境的 root shell。
- `chroot #`：已经进入 `/mnt/gentoo` 后的 root shell。
- `gentoo #`：第一次重启后的 Gentoo root shell，通常通过 `sudo -i` 获得。
- `yurikon $`：普通用户。
- `<PUBLIC_KEY_FILE>`、`<BACKUP_MOUNT>` 等尖括号内容必须替换，不能原样执行。
- 所有长时间任务都在 `screen` 中运行。
- 远程期间不要随意执行 `rc-service NetworkManager restart`、修改正在使用的网卡，
  或启用 Mihomo TUN。
- 每个 `emerge` 先用 `emerge --pretend --verbose ...` 查看计划；不要不审阅地接受
  autounmask 写入。
- 首次成功进入桌面不代表备份可以删除。至少保留到所有验收完成一周以后。

远程会话建议：

```sh
live # screen -S gentoo-install
```

断线重连：

```sh
live # screen -ls
live # screen -r gentoo-install
```

## 2. 重装前必须完成的准备

### 2.1 冻结配置基线

当前 `/home/yurikon/nixos-config` 的主分支名是 `master`，不是 `main`。审计时 HEAD 与
`origin/master` 都是 `ecf1ba0`，工作树干净；仍要在真正重装前再次检查，因为这只代表
2026-07-29 这次审计时的状态。

在旧 NixOS 中记录：

```sh
git -C /home/yurikon/nixos-config branch --show-current
git -C /home/yurikon/nixos-config rev-parse HEAD
git -C /home/yurikon/nixos-config status --short
git -C /home/yurikon/nixos-config diff --binary
git -C /home/yurikon/nixos-config diff --cached --binary
```

至少完整复制：

- `/home/yurikon/nixos-config/`
- `/home/yurikon/nixos-to-gentoo/`
- 两个仓库届时出现的未提交工作、未跟踪文件和 `.git`。

`ecf1ba0` 已纳入 Sway 双屏与跨输出操作、Emacs CTeX/XeLaTeX、Codeberg SSH/直连、
locale 键位和 Mihomo 规则等迁移重点。不要退回旧的 `92e338f` 快照，也不要只复制
Nix 文件而遗漏其引用的原生配置文件。

### 2.2 完成不可替代数据备份

严格执行配套审计清单的第 3 节和第 9 节。备份目标必须是 Linux 文件系统或能保留
owner、mode、ACL、xattr 和符号链接的备份仓库。当前 2TB 盘本身不是它自己的备份。

迁移前最低要求：

- [ ] `/home/yurikon` 有一份与 2TB 物理独立的完整备份。
- [ ] ESP 全量备份。
- [ ] `/etc` 和 `/var` 中需迁移的 root-only 状态已经用 `sudo` 备份。
- [ ] 备份生成文件清单和校验文件，并做过抽样恢复。
- [ ] 明确接受格式化 512GB 根分区会删除当前 NixOS。

root-only 状态重点：

- `/etc/mihomo/`
- Mihomo 的 provider、GeoIP/GeoSite 和选择状态目录
- `/var/lib/tailscale/`
- `/etc/NetworkManager/system-connections/`
- `/etc/ssh/ssh_host_*`
- `/var/lib/bluetooth/`
- `/var/lib/lockdown/`
- `/etc/cups/`、打印/扫描的本地配置
- `/var/lib/jellyfin/`
- Docker、libvirt 状态（当前盘点表明没有容器/卷和 VM，但仍要现场复核）

用户秘密使用单独加密备份：

- `~/.ssh`、`~/.gnupg`
- `~/.config/sops/age/keys.txt`
- `~/.config/rclone/rclone.conf`
- Mihomo 订阅、节点/provider 文件
- 邮箱凭据、OAuth token、浏览器会话

不要把这些秘密写进本仓库。

### 2.3 准备“离线安装包”

远程重装不能把“先下载代理软件”建立在已经能访问外网的假设上。准备第二只 USB、
加密移动盘，或 Ventoy 的可写数据区，至少携带：

- 官方 Gentoo Minimal ISO、`.asc`，以及已核对的签名信息。
- 当前 `stage3-amd64-openrc-*.tar.xz`、对应 `.asc` 和 `.DIGESTS`。
- `portage-YYYYMMDD.tar.xz`、`.gpgsig`；用于完全无法同步时。
- 当前 amd64 Mihomo 上游二进制和上游校验文件。
- 临时 Mihomo 配置和已经下载好的 provider 文件。
- 自己的 SSH 公钥；不要只带私钥。
- 本文档和迁移审计清单的离线副本。
- 有线网卡所需的特殊固件；官方 ISO 不识别网卡时可救援。

临时 Mihomo 配置必须满足：

- `mixed-port: 7890`
- `allow-lan: false`
- `external-controller` 只监听 `127.0.0.1`
- `tun.enable: false`
- provider 改为本地 `type: file`，不依赖启动后再下载订阅
- 配置与 provider 文件权限 `0600`

先在旧系统验证离线副本：

```sh
sudo mihomo -t -d <OFFLINE_KIT>/mihomo \
  -f <OFFLINE_KIT>/mihomo/live-config.yaml
```

### 2.4 网络的三条可用路径

安装时依次尝试，不要同时叠加：

1. 直连 Gentoo 官方 CDN。
2. 国内 Gentoo 镜像。
3. 本地 `127.0.0.1:7890` 临时代理。

2026-07-29 的 Gentoo 官方 mirror status 显示 USTC 和 NJU 可用。镜像状态会变化，
现场必须重新探测：

```sh
curl -I --max-time 15 \
  https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt

curl -I --max-time 15 \
  https://mirrors.nju.edu.cn/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt
```

本手册默认国内镜像：

```text
https://mirrors.ustc.edu.cn/gentoo/
https://mirrors.nju.edu.cn/gentoo/
```

镜像只改变下载位置，不降低签名校验要求。不要使用官方状态页已显示长期过期的镜像。

## 3. 启动 Live 环境并建立 SSH

### 3.1 本地控制台：确认 UEFI 和网络

在固件中：

- 选择带 `UEFI:` 前缀的 USB 启动项。
- 首次安装建议暂时关闭 Secure Boot。
- 优先使用有线网络。
- 保留本地屏幕和键盘，至少直到第一次 Gentoo SSH 登录成功。

进入 Live 环境：

```sh
live # test -d /sys/firmware/efi && echo UEFI-OK
live # ip -br link
live # ip -br addr
live # ip route
live # ping -c 3 1.1.1.1
live # curl --location --max-time 20 https://www.gentoo.org/ --output /dev/null
```

IP 连通但域名失败时，先修 DNS；域名可解析但外部站点失败时再切镜像或代理。

### 3.2 安装 SSH 公钥并启动 sshd

从安全 USB 读取自己的公钥：

```sh
live # install -d -m 700 /root/.ssh
live # install -m 600 <PUBLIC_KEY_FILE> /root/.ssh/authorized_keys
live # install -m 600 <PUBLIC_KEY_FILE> \
  /run/gentoo-install-authorized-key.pub
```

确认文件是一行以 `ssh-ed25519` 或其他预期 key type 开头的公钥：

```sh
live # ssh-keygen -lf /root/.ssh/authorized_keys
```

为 Live 环境只允许 root 使用公钥登录：

```sh
live # install -d -m 755 /etc/ssh/sshd_config.d
live # nano /etc/ssh/sshd_config.d/90-live-install.conf
```

内容：

```text
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
```

检查并启动：

```sh
live # sshd -t
live # sshd -T | grep -E \
  '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
live # rc-service sshd start
live # ss -lntp | grep ':22'
live # ip -br addr
live # ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

记录 Live host key 指纹和 IP。

从管理端首次连接：

```sh
ssh root@<LIVE_IP>
```

不要关闭这个连接。再开第二个终端，重复登录并运行：

```sh
whoami
ip route
screen -S gentoo-install
```

### 检查点 SSH-LIVE

以下全部满足后，可以离开目标机前，转为 SSH 安装：

- [ ] 两个独立 SSH 会话均可用。
- [ ] 认证只使用预期公钥。
- [ ] 已记录 Live IP 和 host key 指纹。
- [ ] `screen -S gentoo-install` 已建立。
- [ ] 有线网络稳定，或现场有人能恢复网络。
- [ ] 管理端可以通过本地控制台联系到目标机。

从这里到第一次重启均连接的是 Live 环境；进入 chroot 不会另开一个 sshd。

## 4. 在大规模下载前建立镜像或临时代理

### 4.1 先选直连或镜像

分别测试官方 CDN 和 USTC：

```sh
live # curl -L --max-time 20 -o /dev/null -w '%{http_code} %{speed_download}\n' \
  https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt

live # curl -L --max-time 20 -o /dev/null -w '%{http_code} %{speed_download}\n' \
  https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt
```

有一条稳定即可继续。不要仅凭 `ping` 判断 HTTPS 可用。

### 4.2 外部网络不可用时启动临时 Mihomo

把离线介质中的 Mihomo 文件复制到 Live 的 tmpfs。不要直接从包含秘密的 USB 目录运行：

```sh
live # install -d -m 700 /run/install-net
live # install -m 700 <OFFLINE_KIT>/mihomo/mihomo /run/install-net/mihomo
live # install -m 600 <OFFLINE_KIT>/mihomo/live-config.yaml \
  /run/install-net/config.yaml
live # cp -a <OFFLINE_KIT>/mihomo/providers /run/install-net/
live # chmod -R go-rwx /run/install-net
live # /run/install-net/mihomo -t -d /run/install-net \
  -f /run/install-net/config.yaml
```

另开一个 `screen`：

```sh
live # screen -dmS mihomo-live \
  /run/install-net/mihomo -d /run/install-net -f /run/install-net/config.yaml
live # ss -lntp | grep ':7890'
```

只给当前安装 shell 注入代理：

```sh
live # export http_proxy=http://127.0.0.1:7890
live # export https_proxy=http://127.0.0.1:7890
live # export all_proxy=socks5h://127.0.0.1:7890
live # export no_proxy=localhost,127.0.0.1,::1,<LAN_CIDR>
```

验证：

```sh
live # curl --proxy http://127.0.0.1:7890 \
  -I --max-time 20 https://distfiles.gentoo.org/
```

禁止事项：

- 不在 Live 环境启用 TUN、自动路由或 DNS hijack。
- 不把代理环境变量写入管理端 SSH 客户端。
- 不在 SSH 安装期间重启网卡或 NetworkManager。
- 不在 shell 历史中输入带用户名、密码或 token 的代理 URL。

### 检查点 NET

- [ ] Stage 3 URL 连续测试两次成功。
- [ ] 选定了唯一主路径：官方、国内镜像或临时代理。
- [ ] 代理路径下确认 `tun.enable: false`。
- [ ] 系统时间大致正确，否则 TLS 和签名验证可能失败。

## 5. 最后一次确认磁盘并格式化 512GB 根分区

### 5.1 识别磁盘

```sh
live # ls -l /dev/disk/by-id/ | grep -E 'Micron|KIOXIA'
live # lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,FSTYPE,UUID,PARTUUID,MOUNTPOINTS
live # blkid
```

必须确认：

- Micron `220434EACA5D` 是约 476.9 GiB。
- Micron part1 是 1 GiB FAT32、UUID `B552-1C1F`。
- Micron part2 是约 475.9 GiB。
- KIOXIA `2FCKS0F5Z0E8` 是约 1.8 TiB。
- KIOXIA 两个 ext4 分区 UUID 与第 0.3 节一致。

把当前表保存到备份介质：

```sh
live # lsblk -f > <BACKUP_MOUNT>/pre-format-lsblk.txt
live # sfdisk --dump \
  /dev/disk/by-id/nvme-Micron_MTFDKBA512TFH_220434EACA5D \
  > <BACKUP_MOUNT>/micron-partition-table.sfdisk
live # sfdisk --dump \
  /dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G3_SSD_2FCKS0F5Z0E8 \
  > <BACKUP_MOUNT>/kioxia-partition-table.sfdisk
```

### 5.2 格式化唯一目标

以下命令会永久删除当前 NixOS 根分区。它不会改 ESP，也不会改 2TB 盘：

```sh
live # mkfs.ext4 -L gentoo-root \
  /dev/disk/by-id/nvme-Micron_MTFDKBA512TFH_220434EACA5D-part2
```

不要执行 `mkfs` 到整盘、Micron part1、任何 KIOXIA 路径或 `/dev/nvme0n1*`。

### 5.3 挂载根和 ESP

```sh
live # mount \
  /dev/disk/by-id/nvme-Micron_MTFDKBA512TFH_220434EACA5D-part2 \
  /mnt/gentoo
live # install -d -m 700 /mnt/gentoo/boot
live # mount \
  /dev/disk/by-id/nvme-Micron_MTFDKBA512TFH_220434EACA5D-part1 \
  /mnt/gentoo/boot
live # findmnt -T /mnt/gentoo
live # findmnt -T /mnt/gentoo/boot
live # lsblk -f
```

记录新根 UUID：

```sh
live # blkid \
  /dev/disk/by-id/nvme-Micron_MTFDKBA512TFH_220434EACA5D-part2
```

后文的 `<NEW_ROOT_UUID>` 使用这里的新值，绝不能继续用旧 NixOS UUID。

## 6. Stage 3、Portage 和 chroot

### 6.1 获取并验证 Stage 3

优先从已经通过检查点 NET 的来源下载。使用 USTC 时，在下面目录选择
`stage3-amd64-openrc-*.tar.xz`，同时下载 `.asc` 和 `.DIGESTS`：

```text
https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/
```

下载到 `/mnt/gentoo`，然后：

```sh
live # cd /mnt/gentoo
live # gpg --import /usr/share/openpgp-keys/gentoo-release.asc
live # gpg --verify stage3-amd64-openrc-*.tar.xz.asc
live # gpg --verify stage3-amd64-openrc-*.tar.xz.DIGESTS
```

输出必须包含预期 Gentoo Release Engineering 的 `Good signature`。签名通过后：

```sh
live # tar xpvf stage3-amd64-openrc-*.tar.xz \
  --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
```

### 6.2 设置 Portage 下载路径

编辑 `/mnt/gentoo/etc/portage/make.conf`，保留 Stage 3 原有设置，仅追加：

```text
COMMON_FLAGS="-march=native -O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
USE="dist-kernel"
GENTOO_MIRRORS="https://mirrors.ustc.edu.cn/gentoo/ https://mirrors.nju.edu.cn/gentoo/"
```

第一轮不要设置激进 LTO、`-*`、全局 `~amd64` 或过大的 `MAKEOPTS`。先稳定启动。

若使用临时代理，把代理环境复制给 chroot 会话，而不是写死秘密：

```sh
live # cp --dereference /etc/resolv.conf /mnt/gentoo/etc/resolv.conf
```

### 6.3 挂载伪文件系统并进入 chroot

```sh
live # mount --types proc /proc /mnt/gentoo/proc
live # mount --rbind /sys /mnt/gentoo/sys
live # mount --make-rslave /mnt/gentoo/sys
live # mount --rbind /dev /mnt/gentoo/dev
live # mount --make-rslave /mnt/gentoo/dev
live # mount --bind /run /mnt/gentoo/run
live # mount --make-slave /mnt/gentoo/run
live # chroot /mnt/gentoo /bin/bash
chroot # source /etc/profile
chroot # export PS1="(chroot) ${PS1}"
```

使用临时代理时，在 chroot 内重新导出第 4.2 节的四个代理变量。因为 `/run` 已 bind，
`127.0.0.1:7890` 仍指向 Live 环境的 Mihomo。

### 6.4 获取 ebuild repository

受限网络优先：

```sh
chroot # emerge-webrsync
```

`emerge-webrsync` 使用 Web 下载每日快照，通常比 rsync 更容易穿过代理和防火墙。
不要求小时级最新时，不必紧接着执行 `emerge --sync`。

完全断网但已携带快照时，把 `portage-YYYYMMDD.tar.xz`、`.gpgsig` 放入
`/var/cache/distfiles`，再执行：

```sh
chroot # emerge-webrsync --revert=YYYYMMDD
```

日期必须与文件名一致。不要仅手工解压后跳过签名验证。

检查：

```sh
chroot # eselect profile list
chroot # emerge --info
chroot # eselect news read
```

选择当前 amd64、23.0、OpenRC、glibc、multilib 的 desktop profile。不要按文档写死
profile 编号；用 `eselect profile list` 的现场结果选择，并再次确认路径中没有
`systemd`、`no-multilib` 或 `musl`。

### 6.5 可选官方 binary package

Stage 3 如果已经提供与当前 profile 匹配的 `/etc/portage/binrepos.conf`，可使用：

```text
FEATURES="${FEATURES} getbinpkg binpkg-request-signature"
```

然后：

```sh
chroot # getuto
chroot # emerge --info | grep -i bin
```

只使用 profile 路径完全匹配的 binhost。国内镜像没有相同路径时，退回源码编译，
不要把另一个 profile 的二进制包地址硬套进来。

## 7. 配置基本系统

### 7.1 时区和 locale

```sh
chroot # ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

`/etc/locale.gen`：

```text
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
```

生成：

```sh
chroot # locale-gen
chroot # eselect locale list
chroot # eselect locale set en_US.utf8
chroot # env-update
chroot # source /etc/profile
```

先用 `LANG=en_US.UTF-8` 保证日志和救援命令可读；中文输入与区域格式在桌面会话配置。

### 7.2 主机名和 hosts

建议新主机名用 `gentoo`，避免把新 SSH host key 与旧 `nixos` 混淆：

`/etc/conf.d/hostname`：

```text
hostname="gentoo"
```

`/etc/hosts` 至少包含：

```text
127.0.0.1 localhost
127.0.1.1 gentoo
::1       localhost gentoo
```

### 7.3 fstab：首启只挂 512GB

先获取 UUID：

```sh
chroot # blkid
```

`/etc/fstab` 首次启动版本：

```fstab
UUID=<NEW_ROOT_UUID>  /      ext4  defaults,noatime                       0 1
UUID=B552-1C1F        /boot  vfat  noatime,fmask=0077,dmask=0077          0 2
```

第一次启动前不要加入 2TB、bind mount 或旧 swapfile。这样即使 2TB 不存在也能登录。

### 7.4 用户、Bash 和 sudo

安装基础工具：

```sh
chroot # emerge --pretend --verbose \
  app-admin/sudo app-shells/bash-completion dev-vcs/git \
  net-misc/openssh net-misc/chrony app-admin/sysklogd \
  sys-process/cronie
chroot # emerge --ask \
  app-admin/sudo app-shells/bash-completion dev-vcs/git \
  net-misc/openssh net-misc/chrony app-admin/sysklogd \
  sys-process/cronie
```

创建 UID 1000、主组 `users`、登录 shell `/bin/bash` 的本地新 home：

```sh
chroot # useradd -m -u 1000 -g users \
  -G wheel,plugdev,audio,video \
  -s /bin/bash yurikon
chroot # passwd yurikon
chroot # passwd root
```

如果某个附加组尚不存在，先省略，安装对应服务后用 `usermod -aG` 加入。不要创建
Fish 用户，也不要把 2TB 旧 home 直接挂到 `/home`。

用 `visudo` 创建 `/etc/sudoers.d/10-yurikon`：

```text
%wheel ALL=(ALL:ALL) ALL
```

验证：

```sh
chroot # visudo -c
chroot # getent passwd yurikon
chroot # id yurikon
```

### 7.5 安装新系统的 SSH key

只复制 `authorized_keys`，不要在此时把用户私钥放进根分区：

```sh
chroot # install -d -o yurikon -g users -m 700 /home/yurikon/.ssh
chroot # install -o yurikon -g users -m 600 \
  /run/gentoo-install-authorized-key.pub \
  /home/yurikon/.ssh/authorized_keys
```

`/etc/ssh/sshd_config.d/10-remote-install.conf`：

```text
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AllowUsers yurikon
```

生成并记录新系统 host key：

```sh
chroot # ssh-keygen -A
chroot # sshd -t
chroot # ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

将这个指纹复制到管理端安全位置。

### 7.6 日志、时间和 OpenRC

```sh
chroot # rc-update add sysklogd default
chroot # rc-update add cronie default
chroot # rc-update add chronyd default
chroot # rc-update add sshd default
```

在 `/etc/rc.conf` 设置：

```text
rc_logger="YES"
```

这样启动日志会写入 `/var/log/rc.log`。

## 8. 网络：安装 NetworkManager，但不切断 Live SSH

安装并让新系统在下次启动时接管：

```sh
chroot # emerge --pretend --verbose net-misc/networkmanager
chroot # emerge --ask net-misc/networkmanager
chroot # rc-update add dbus default
chroot # rc-update add NetworkManager default
```

确认用户有 `plugdev`：

```sh
chroot # usermod -aG plugdev yurikon
```

只保留一个网络管理栈。新系统选择 NetworkManager 后，不要同时把 `dhcpcd` 或
`net.*` 加入 default runlevel。

远程首次启动强烈建议用有线 DHCP。若只能用 Wi-Fi：

1. 从加密备份恢复对应 NetworkManager keyfile。
2. 放入 `/etc/NetworkManager/system-connections/`。
3. owner 为 `root:root`、mode 为 `0600`。
4. 现场复核 SSID、接口和密钥。
5. 没有本地控制台回退时，不要冒险第一次重启。

不要在 chroot 中尝试启动 NetworkManager；chroot 仍共享 Live 的运行内核和网络。

## 9. 内核、固件和 systemd-boot

### 9.1 installkernel 设置

`/etc/portage/package.use/systemd-boot`：

```text
sys-apps/systemd-utils boot kernel-install
sys-kernel/installkernel dracut systemd systemd-boot
sys-kernel/gentoo-kernel-bin initramfs
sys-firmware/intel-microcode dist-kernel initramfs
```

`/etc/portage/make.conf` 已有：

```text
USE="dist-kernel"
```

安装：

```sh
chroot # emerge --pretend --verbose \
  sys-apps/systemd-utils sys-kernel/installkernel \
  sys-kernel/linux-firmware sys-firmware/intel-microcode
chroot # emerge --ask \
  sys-apps/systemd-utils sys-kernel/installkernel \
  sys-kernel/linux-firmware sys-firmware/intel-microcode
```

本机是 Intel Core i5-12500H，`sys-firmware/intel-microcode` 是必装项；
`sys-kernel/linux-firmware` 同时提供 Intel i915 所需的 DMC、GuC/HuC 固件。
如果 microcode 因 license 停止，只对 `sys-firmware/intel-microcode` 接受 Portage
现场列出的 `intel-ucode` license，不全局放开 license。

### 9.2 内核命令行和安装

`/etc/kernel/cmdline`：

```text
root=UUID=<NEW_ROOT_UUID> rw rootfstype=ext4 nvidia_drm.modeset=1
```

首启不要加 `quiet`，远程排错需要完整日志。

确保 ESP 正确挂载：

```sh
chroot # findmnt -T /boot
chroot # test -d /sys/firmware/efi && echo UEFI-OK
```

安装引导器与内核：

```sh
chroot # bootctl --esp-path=/boot install
chroot # emerge --ask sys-kernel/gentoo-kernel-bin
chroot # bootctl --esp-path=/boot list
chroot # find /boot -maxdepth 4 -type f -printf '%p\n'
```

必须看到内核和 initramfs 对应的引导项。分发内核默认依赖 initramfs，所以在安装
kernel 前必须已经让 `installkernel` 使用 `dracut`。

若引导项未生成，不要重启。检查：

```sh
chroot # emerge --config sys-kernel/gentoo-kernel-bin
chroot # bootctl --esp-path=/boot list
chroot # efibootmgr -v
```

### 9.3 转入本机硬件专章

内核装好后，继续执行第 10 章。该章会安装 Intel/NVIDIA 驱动、为 i915 重建
initramfs，并建立 NVIDIA 运行时电源管理；完成第 10.2 节和第 10.8 节的首启前检查
后，才能进入后面的第一次重启门槛。

## 10. 本机硬件专章：i5-12500H + Iris Xe + RTX 2050

本章以当前机器为唯一目标，不再保留 AMD 假设。它覆盖安装前已核实到的硬件：

| 角色 | 本机设备 | PCI 地址与 ID | Gentoo 驱动 |
| --- | --- | --- | --- |
| CPU | Intel Core i5-12500H，12 核 16 线程 | family 6，model 154 | `intel-microcode`、`kvm-intel` |
| 桌面 GPU | Alder Lake-P GT2 / Iris Xe | `0000:00:02.0`、`8086:46a6` | 内核 `i915`、Mesa Intel |
| 按需 GPU | NVIDIA GA107M / RTX 2050 | `0000:01:00.0`、`10de:25a9` | `nvidia-drivers[kernel-open]` |

当前 NixOS 的可用拓扑是：

```text
内屏 + 外接显示器
        |
        v
Intel Iris Xe / i915  <--- Sway、Wayland、XWayland、视频解码
        ^
        | PRIME render offload
NVIDIA RTX 2050       <--- 只在游戏、Vulkan/OpenGL 或计算任务时唤醒
```

本章跨越重启前后，执行顺序不能按页面一直向下冲：

1. 当前 chroot 中执行第 10.1、10.2 和 10.8 节的“首启前”部分。
2. 执行第 11 章并重启，在第 12 章完成永久 SSH。
3. 回到第 10.3 和 10.8 节做基础硬件核验。
4. 第 16.1 节装好 Sway/elogind 后，再执行第 10.4 至 10.7 节。

这不是传统的“在两个完整桌面驱动之间切换”。不要生成 `/etc/X11/xorg.conf`，不要把
NixOS 的 `PCI:0:2:0`、`PCI:1:0:0` 写成 Xorg `BusID`，也不要让 RTX 2050 承担
Sway 合成。两个 PCI 地址只用于稳定设备路径、核验和故障排查。

### 10.1 首次重启前安装 CPU、Intel 和 NVIDIA 支持

本机 Gen 12 Intel 图形继续使用成熟的 `i915`。即使新内核同时提供 `xe` 模块，也不要
添加强制 xe probe 参数；本机迁移基线是当前正在工作的 `i915`。

创建 `/etc/portage/package.use/00video`：

```text
*/* VIDEO_CARDS: -* intel nvidia
```

创建 `/etc/portage/package.use/nvidia`：

```text
x11-drivers/nvidia-drivers dist-kernel kernel-open modules tools wayland -persistenced -powerd
x11-drivers/nvidia-drivers ABI_X86: 64 32
media-libs/mesa ABI_X86: 64 32
media-libs/vulkan-loader ABI_X86: 64 32
```

说明：

- RTX 2050 属于 Ampere，支持 NVIDIA open kernel modules；这也与当前 NixOS 的
  `hardware.nvidia.open = true` 一致。
- `dist-kernel` 使 NVIDIA 模块跟随 `gentoo-kernel-bin` 更新重建。
- 不启用 `persistenced`：它面向需要长期保留 GPU 状态的场景，不适合希望独显空闲
  断电的 PRIME 笔记本。
- `powerd` 只对应部分机器的 Dynamic Boost；第一阶段不把它当必需服务。
- 32 位 ABI 为后续 Steam/Proton 预留。若本轮不装 Steam，可以先删除三行
  `ABI_X86`，到安装 Steam 时再加入并让 Portage 完整解析依赖。

先审阅安装计划：

```sh
chroot # emerge --pretend --verbose \
  sys-firmware/intel-microcode sys-firmware/sof-firmware \
  sys-kernel/linux-firmware \
  media-libs/mesa media-libs/libva-intel-media-driver \
  media-libs/vulkan-loader dev-util/vulkan-tools \
  x11-apps/mesa-progs x11-drivers/nvidia-drivers
```

如果 Portage 因 NVIDIA license 停止，只在 `/etc/portage/package.license/nvidia`
接受现场错误信息列出的 NVIDIA driver license。例如安装日仍为该标识时：

```text
x11-drivers/nvidia-drivers NVIDIA-2025
```

不要为此全局设置 `ACCEPT_LICENSE="*"`。重新审阅计划后安装：

```sh
chroot # emerge --ask \
  sys-firmware/intel-microcode sys-firmware/sof-firmware \
  sys-kernel/linux-firmware \
  media-libs/mesa media-libs/libva-intel-media-driver \
  media-libs/vulkan-loader dev-util/vulkan-tools \
  x11-apps/mesa-progs x11-drivers/nvidia-drivers
```

安装后确认实际选中了本机需要的 USE/ABI：

```sh
chroot # emerge --info x11-drivers/nvidia-drivers media-libs/mesa
chroot # equery uses x11-drivers/nvidia-drivers
chroot # modinfo i915 | head
chroot # modinfo nvidia | head
chroot # modinfo nvidia_drm | head
```

若 `equery` 尚未安装，可先用 `emerge --ask app-portage/gentoolkit`；不要因为少一个
检查工具跳过 `emerge --info` 和 `modinfo`。

### 10.2 initramfs、模块加载和首启前检查

为 Intel 添加 early KMS。创建 `/etc/dracut.conf.d/20-intel-gpu.conf`：

```text
add_drivers+=" i915 "
```

RTX 2050 不承担启动画面或根文件系统访问，不需要塞入 initramfs。创建
`/etc/dracut.conf.d/30-nvidia-offload.conf`：

```text
omit_drivers+=" nvidia nvidia_drm nvidia_modeset nvidia_uvm "
```

让完整系统启动后再装入 NVIDIA 模块。创建 `/etc/modules-load.d/nvidia.conf`：

```text
nvidia
nvidia_modeset
nvidia_drm
nvidia_uvm
```

`i915` 和 `kvm-intel` 通常会由 udev 根据硬件自动加载；若首启核验没有加载，再各加一
行到 `/etc/modules-load.d/local.conf`，不要预先堆入无关模块。

为本机独显启用细粒度 Runtime D3。创建 `/etc/modprobe.d/nvidia-power.conf`：

```text
options nvidia NVreg_DynamicPowerManagement=0x02
```

新版 `nvidia-drivers` 可能已经安装等价的 udev 规则。先检查：

```sh
chroot # grep -R "power/control.*auto" \
  /usr/lib/udev/rules.d /lib/udev/rules.d 2>/dev/null | grep -i nvidia
```

只有没有等价规则时，创建 `/etc/udev/rules.d/80-nvidia-pm.rules`：

```udev
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
```

这个规则只处理本机 `3D controller` 类别，不复制 NVIDIA 文档中删除 USB、音频或
Type-C PCI function 的旧规则；本机没有必要删除并不存在的 function。

重建模块依赖和 initramfs：

```sh
chroot # update-modules
chroot # emerge --config sys-kernel/gentoo-kernel-bin
chroot # bootctl --esp-path=/boot list
```

不要在 chroot 中无参数运行 `dracut --force`：它看到的是 Live ISO 正在运行的内核
版本。`emerge --config` 会让 installkernel 针对已经安装的 Gentoo kernel 重新生成
正确的 initramfs 和引导项。

确认 `/etc/kernel/cmdline` 仍包含：

```text
nvidia_drm.modeset=1
```

然后完成首启前的本机硬件门槛：

- [ ] `intel-microcode`、`linux-firmware`、`sof-firmware` 和
  `gentoo-kernel-bin` 已安装。
- [ ] `VIDEO_CARDS` 恰好包含 `intel nvidia`，没有 `amdgpu`、`radeonsi`、
  `nouveau`。
- [ ] NVIDIA 驱动启用了 `dist-kernel kernel-open modules wayland`。
- [ ] `modinfo i915`、`modinfo nvidia`、`modinfo nvidia_drm` 都能找到当前内核模块。
- [ ] initramfs 包含 `i915`，但不包含 NVIDIA 四个模块。
- [ ] systemd-boot 的 Gentoo 项指向最新 kernel 和重新生成的 initramfs。
- [ ] 尚未启用 greetd；即使 NVIDIA 有问题，首启仍保留 Intel TTY 和 SSH 回退。

检查 initramfs 时可用：

```sh
chroot # find /boot -type f \( -iname '*initramfs*' -o -iname '*initrd*' \)
chroot # lsinitrd <GENTOO_INITRAMFS_PATH> | \
  grep -E '/i915\\.ko|/nvidia(_drm|_modeset|_uvm)?\\.ko'
```

把 `<GENTOO_INITRAMFS_PATH>` 替换为上一个命令列出的新 Gentoo initramfs 绝对路径。
预期能看到 `i915`，看不到 NVIDIA 四个模块。完成后继续第 11 章。

### 10.3 第一次启动后的硬件核验

到达 **检查点 SSH-INSTALLED** 后，以 SSH 运行：

```sh
sudo lspci -nnk
sudo dmesg | grep -Ei 'microcode|i915|nvidia|drm|firmware'
ls -l /dev/dri /dev/dri/by-path
lsmod | grep -E '^(i915|nvidia|nvidia_drm|nvidia_modeset|nvidia_uvm|kvm_intel)\\b'
cat /sys/module/nvidia_drm/parameters/modeset
nvidia-smi
```

必须得到：

- `00:02.0 [8086:46a6]` 的 `Kernel driver in use` 是 `i915`。
- `01:00.0 [10de:25a9]` 的 `Kernel driver in use` 是 `nvidia`，不是 `nouveau`。
- 存在 `/dev/dri/by-path/pci-0000:00:02.0-card` 和对应 Intel render node。
- `nvidia_drm` 的 modeset 值为 `Y`。
- `dmesg` 没有缺少 i915 DMC、GuC/HuC 固件或 NVIDIA module API mismatch。

`nvidia-smi` 会主动唤醒独显，所以它只用来验证驱动，不能用来判断独显是否已经省电。

若 NVIDIA 模块首启失败，不要阻塞 SSH、存储和 Bash 恢复。Sway 可以继续只用 Intel：

1. 保留第 10.5 节的 Intel DRM 启动包装器。
2. 暂时从 `/etc/modules-load.d/nvidia.conf` 删除 NVIDIA 四行。
3. 重新启动后确认 Intel/Sway 闭环。
4. 再检查 `dmesg`、当前 kernel 对应的 `modinfo nvidia` 和
   `emerge @module-rebuild`。

紧急时可在 systemd-boot 编辑当前启动项，临时追加：

```text
module_blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm
```

它只用于单次 Intel 救援启动，不写回正常 `/etc/kernel/cmdline`。若
`kernel-open` 在安装日的稳定驱动上确实失败，记录完整构建/内核日志后，可临时移除
该 USE flag 并重装闭源 kernel module；不要同时安装 nouveau。

### 10.4 安装并验证 Intel 桌面用户态

第 16 章安装 Sway 会话基础后，先在 TTY 中确认 Intel 是默认 renderer。需要的检查
工具若尚未装齐：

```sh
gentoo # emerge --pretend --verbose \
  media-libs/mesa media-libs/libva-intel-media-driver \
  media-libs/vulkan-loader dev-util/vulkan-tools \
  x11-apps/mesa-progs
gentoo # emerge --ask \
  media-libs/mesa media-libs/libva-intel-media-driver \
  media-libs/vulkan-loader dev-util/vulkan-tools \
  x11-apps/mesa-progs
```

`vainfo` 的包名可能随安装日仓库调整，先运行：

```sh
gentoo # emerge --search libva-utils
```

再安装搜索结果中的官方包。Intel Gen 12 使用 `libva-intel-media-driver`（iHD），不使用
面向旧硬件的 `libva-intel-driver`。

用户必须能访问 seat 和 render node：

```sh
yurikon $ id
yurikon $ getfacl /dev/dri/renderD128
yurikon $ loginctl session-status
```

`elogind` 正常时设备 ACL 会跟随本地 session 设置；`yurikon` 也已在 `video` 组。
不要把 `/dev/dri/*` 粗暴改成 world-writable。

### 10.5 强制 Sway 只使用 Intel

DRM 的 `card0`、`card1` 编号可能因 simpledrm 和模块加载顺序变化，不能写死。使用本机
PCI 地址生成的稳定 symlink。创建 `/usr/local/bin/start-sway-intel`：

```sh
#!/bin/sh

intel_drm=/dev/dri/by-path/pci-0000:00:02.0-card

if [ ! -e "$intel_drm" ]; then
    echo "Intel DRM device missing: $intel_drm" >&2
    echo "Refusing to start Sway on an unintended GPU." >&2
    exit 1
fi

export WLR_DRM_DEVICES="$intel_drm"
exec /usr/bin/dbus-run-session /usr/bin/sway "$@"
```

设置：

```sh
gentoo # chown root:root /usr/local/bin/start-sway-intel
gentoo # chmod 0755 /usr/local/bin/start-sway-intel
```

手动首测：

```sh
yurikon $ /usr/local/bin/start-sway-intel -d 2>~/sway-debug.log
```

注意边界：

- `WLR_DRM_DEVICES=...` 是 **启动 Sway 之前的环境变量**，不是 Sway 配置指令；不要把
  它写进 `~/.config/sway/config`。
- 不默认加 `--unsupported-gpu`。Sway 的 renderer 是 Intel/i915，并非 NVIDIA。
- 不默认设置 `WLR_NO_HARDWARE_CURSORS`、`WLR_DRM_NO_MODIFIERS` 或软件 renderer。
  这些都是出现对应故障并保留 debug log 后才测试的临时诊断变量。
- 当前内屏和外接屏都由 Intel 驱动；若将来更换硬件或发现某接口实际接到 NVIDIA，
  重新核实 DRM connector，不能继续套用本章。

进入 Sway 后：

```sh
yurikon $ swaymsg -t get_outputs
yurikon $ swaymsg -t get_version
yurikon $ glxinfo -B
yurikon $ vulkaninfo --summary
```

默认 `glxinfo -B` 和默认 Vulkan 设备应显示 Mesa Intel。若显示 llvmpipe，先修复
elogind/ACL、Mesa 和 Intel DRM，不能用 NVIDIA 包装器掩盖问题。

第 16.2 节启用 greetd 时，把默认 session 改为：

```toml
[default_session]
command = "/usr/bin/tuigreet --time --remember --cmd /usr/local/bin/start-sway-intel"
user = "greeter"
```

先用 TTY 的 `yurikon` 会话成功运行包装器，再启动 greetd。

### 10.6 NVIDIA PRIME offload 包装器

不要把 NVIDIA 环境变量全局写入 `/etc/environment` 或 Bash profile，否则 Sway、
浏览器和 Emacs 也会无意义地唤醒独显。创建 `/usr/local/bin/prime-run`：

```sh
#!/bin/sh

export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

exec "$@"
```

设置：

```sh
gentoo # chown root:root /usr/local/bin/prime-run
gentoo # chmod 0755 /usr/local/bin/prime-run
```

在已经运行的 Sway 会话中测试：

```sh
yurikon $ glxinfo -B
yurikon $ prime-run glxinfo -B
yurikon $ prime-run vulkaninfo --summary
yurikon $ nvidia-smi
```

预期：

- 不带包装器：renderer 为 Mesa Intel。
- `prime-run glxinfo -B`：OpenGL vendor/renderer 为 NVIDIA/RTX 2050。
- `prime-run vulkaninfo --summary`：首选或唯一可见设备为 RTX 2050。
- 运行 offload 程序时，`nvidia-smi` 能看到该进程。

恢复 Steam 时沿用当前 NixOS 的行为：

```sh
yurikon $ prime-run steam
```

这样 Steam 启动的游戏继承三个变量。若只想让某个游戏使用独显，可把 Steam 游戏启动
参数设为：

```text
prime-run %command%
```

32 位游戏报缺库时，回到第 10.1 节检查 NVIDIA、Mesa 和 Vulkan loader 的
`ABI_X86: 32 64`，再运行 `emerge --ask --changed-use --deep @world`；不要下载另一套
发行版的 `.so` 塞进 `/usr/lib32`。

### 10.7 NVIDIA 空闲断电、挂起和验收

关闭所有 offload 程序后，不运行 `nvidia-smi`，直接检查：

```sh
yurikon $ cat /sys/bus/pci/devices/0000:01:00.0/power/control
yurikon $ cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
yurikon $ cat /proc/driver/nvidia/gpus/0000:01:00.0/power 2>/dev/null
```

目标是 `power/control` 为 `auto`，空闲一段时间后 `runtime_status` 为 `suspended`。
若一直是 `active`：

```sh
yurikon $ sudo lsof /dev/nvidia* \
  /dev/dri/by-path/pci-0000:01:00.0-render 2>/dev/null
yurikon $ pgrep -a 'nvidia-persistenced|Xorg|steam|gamescope'
yurikon $ sudo dmesg | grep -Ei 'nvidia|runtime|D3'
```

重点排除全局 PRIME 变量、常驻 `nvidia-persistenced`、监控程序和未退出的游戏。不要为了
追求 `suspended` 强制 remove 正在使用的 PCI 设备。

当前 Gentoo `nvidia-drivers` 会为 elogind 安装 NVIDIA sleep hook。安装后核实：

```sh
gentoo # find /usr/lib/elogind/system-sleep -maxdepth 1 -type f -o -type l
gentoo # grep -R nvidia /usr/lib/elogind/system-sleep 2>/dev/null
```

不要照搬 systemd 的 `nvidia-suspend.service`、`nvidia-resume.service` 和
`nvidia-hibernate.service`；本系统是 OpenRC + elogind。先完成一次保持 SSH 在线的
suspend/resume 测试：

```sh
yurikon $ sudo loginctl suspend
```

唤醒后通过原 SSH 会话或重新连接检查：

```sh
yurikon $ swaymsg -t get_outputs
yurikon $ sudo dmesg | tail -n 200
yurikon $ prime-run glxinfo -B
```

本机硬件最终验收：

- [ ] CPU microcode 在启动日志中完成 early update。
- [ ] Intel `i915` 驱动内屏、外接屏和 Sway；没有 llvmpipe。
- [ ] 默认 OpenGL/Vulkan 使用 Intel，视频解码使用 Intel iHD。
- [ ] RTX 2050 绑定 `nvidia` open kernel module，`nouveau` 未加载。
- [ ] `prime-run` 的 OpenGL、Vulkan 和 Steam 能使用 RTX 2050。
- [ ] 不运行 offload 程序时独显能进入 runtime suspend。
- [ ] suspend/resume 后显示、Sway、SSH 和 PRIME 均恢复。
- [ ] 即使临时禁用 NVIDIA，Intel + SSH + 最小 Sway 仍可独立工作。

### 10.8 本机其余硬件：首启前保障与首启后验收

本机型号可从 ALSA/DMI 识别为 Lenovo ThinkBook 16 G4 IAP。除 CPU/GPU/磁盘外，当前
系统已核实的关键设备如下：

| 功能 | 设备与 ID | 正常内核驱动 | 额外要求 |
| --- | --- | --- | --- |
| 有线网络 | Intel I219-V `8086:1a1f` | `e1000e` | 首次远程启动的首选链路 |
| Wi-Fi | Intel AX201 `8086:51f0/0074` | `iwlwifi` | `linux-firmware`、NetworkManager |
| Bluetooth | Intel AX201 USB `8087:0026` | `btusb` | `linux-firmware`、BlueZ |
| 音频 | Alder Lake HDA `8086:51c8` | `sof-audio-pci-intel-tgl` | `sof-firmware`、PipeWire |
| 两块 NVMe | Micron 3400、KIOXIA Exceria Plus G3 | `nvme` | 第 5、14 章的磁盘保护规则 |
| SD 读卡器 | O2 Micro `1217:8621` | `sdhci-pci` | 插卡后再做读写验收 |
| Thunderbolt/USB4 | Intel `8086:463e` | `thunderbolt` | 不要求首启即授权外设 |
| 摄像头 | Bison RGB Camera `5986:2146` | `uvcvideo` | PipeWire/浏览器阶段验收 |
| 键鼠/USB | xHCI；当前含 Razer Basilisk V3 | `xhci_pci`、`usbhid` | 不迁移设备数据库或缓存 |

`gentoo-kernel-bin` 应提供这些通用模块。第一次重启前在 chroot 检查：

```sh
chroot # modinfo e1000e
chroot # modinfo iwlwifi
chroot # modinfo btusb
chroot # modinfo snd_sof_pci_intel_tgl
chroot # modinfo nvme
chroot # modinfo sdhci_pci
chroot # modinfo thunderbolt
chroot # modinfo uvcvideo
```

任一“首启必需”模块缺失时不要重启；重新检查是否真的安装了
`sys-kernel/gentoo-kernel-bin` 及其当前 `/lib/modules/<版本>`。有线 `e1000e`、
NVMe、USB 键盘和 Intel `i915` 是本次远程重装的首启硬门槛；摄像头、读卡器和
Thunderbolt 可在永久 SSH 后补验。

`sys-firmware/sof-firmware` 已在第 10.1 节加入安装。AX201 的 Wi-Fi、Bluetooth
firmware 来自 `sys-kernel/linux-firmware`；不要另找过时的独立 Intel firmware
压缩包。

永久 SSH 建立后运行：

```sh
yurikon $ sudo lspci -nnk
yurikon $ sudo lsusb
yurikon $ ip -brief link
yurikon $ nmcli device status
yurikon $ rfkill list
yurikon $ cat /proc/asound/cards
yurikon $ sudo dmesg | grep -Ei \
  'e1000e|iwlwifi|firmware|bluetooth|sof|snd|nvme|sdhci|thunderbolt|uvc'
```

网络必须先满足：

- `enp0s31f6` 由 `e1000e` 驱动并能在重启后自动 DHCP。
- `wlp0s20f3` 由 `iwlwifi` 驱动；需要 Wi-Fi 时再恢复 mode `0600` 的
  NetworkManager keyfile。
- 第一次远程启动不依赖 Wi-Fi；确认 SSH 经有线能反复重连后，才测试无线切换。

Bluetooth 在桌面阶段安装并启用：

```sh
gentoo # emerge --pretend --verbose net-wireless/bluez
gentoo # emerge --ask net-wireless/bluez
gentoo # rc-update add bluetooth default
gentoo # rc-service bluetooth start
yurikon $ bluetoothctl show
```

音频在第 16.3 节启动 PipeWire/WirePlumber 后验收：

```sh
yurikon $ wpctl status
yurikon $ wpctl get-volume @DEFAULT_AUDIO_SINK@
yurikon $ wpctl get-volume @DEFAULT_AUDIO_SOURCE@
```

最终硬件验收：

- [ ] 有线网络、AX201 Wi-Fi、Bluetooth 均使用预期驱动且无 firmware missing。
- [ ] SOF 声卡存在；内置扬声器、耳机、麦克风和 HDMI/DP 音频按实际接口测试。
- [ ] 两块 NVMe 型号、序列号和挂载角色仍与第 0.3 节一致。
- [ ] 触控板、键盘功能键、Razer 鼠标、摄像头、SD 读卡器逐项实测。
- [ ] USB-C/Thunderbolt 若日常使用，完成热插拔、显示和 suspend/resume 测试。
- [ ] `dmesg` 中没有持续的固件加载失败、I/O error 或设备反复 reset。

## 11. 第一次重启前的硬门槛

在 chroot 中逐项运行：

```sh
chroot # emerge --info
chroot # rc-update show
chroot # sshd -t
chroot # visudo -c
chroot # getent passwd yurikon
chroot # findmnt -T /
chroot # findmnt -T /boot
chroot # cat /etc/fstab
chroot # cat /etc/kernel/cmdline
chroot # bootctl --esp-path=/boot list
chroot # efibootmgr -v
chroot # ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

必须确认：

- [ ] `NetworkManager`、`dbus`、`sshd` 在 default runlevel。
- [ ] `dhcpcd` 和 `net.*` 没有同时接管同一接口。
- [ ] `yurikon` 是 UID 1000、shell `/bin/bash`。
- [ ] 新 home 是根文件系统上的普通目录。
- [ ] `authorized_keys` owner/mode 正确。
- [ ] root SSH 被禁用，用户公钥登录已配置。
- [ ] 新 SSH host key 指纹已经离线记录。
- [ ] fstab 只有 512GB root 和 ESP。
- [ ] systemd-boot 能看到 Gentoo kernel/initramfs。
- [ ] 第 10.2 和 10.8 节的本机硬件首启前检查全部通过。
- [ ] 2TB 没被格式化。
- [ ] LiveUSB 仍插着，现场可以从它回退启动。

退出并卸载：

```sh
chroot # exit
live # sync
live # umount -R /mnt/gentoo
```

若提示 busy，不要用 lazy unmount 掩盖问题。先定位仍在使用挂载点的进程：

```sh
live # findmnt -R /mnt/gentoo
live # fuser -vm /mnt/gentoo
```

退出残留的 chroot shell或停止残留进程后，再次 `umount -R /mnt/gentoo`。

然后重启：

```sh
live # reboot
```

SSH 会断开。不要立即删除管理端的旧 host key；先根据控制台或先前记录确认新指纹。

## 12. 第一次启动与永久 SSH

在管理端等待有线 DHCP 地址出现。连接时会看到 host key 改变，因为此前连接的是
Live ISO。只删除这个目标 IP/主机名的旧条目：

```sh
ssh-keygen -R <TARGET_IP_OR_HOST>
ssh yurikon@<TARGET_IP_OR_HOST>
```

对照第 7.5 节记录的新 Ed25519 指纹后才接受。

登录后：

```sh
yurikon $ id
yurikon $ getent passwd "$USER"
yurikon $ sudo -v
yurikon $ sudo rc-status
yurikon $ sudo rc-service NetworkManager status
yurikon $ sudo rc-service sshd status
yurikon $ ip route
yurikon $ curl -I --max-time 20 https://mirrors.ustc.edu.cn/gentoo/
```

### 检查点 SSH-INSTALLED

- [ ] 连接的是新 Gentoo host key，不是 Live host key。
- [ ] 只能以 `yurikon` 公钥登录；root 远程登录失败。
- [ ] `sudo` 正常。
- [ ] NetworkManager 和 sshd 为 started。
- [ ] 断开后能重新连接。
- [ ] 重启一次后仍能重新连接。

从这里开始才把新系统 SSH 当作长期管理入口。防火墙、Tailscale、Mihomo TUN 和桌面
都在此检查点以后启用。

## 13. 优先建立新系统的下载能力

### 13.1 国内镜像持久化

保留 `/etc/portage/make.conf` 中的：

```text
GENTOO_MIRRORS="https://mirrors.ustc.edu.cn/gentoo/ https://mirrors.nju.edu.cn/gentoo/"
```

安装 `mirrorselect` 后可现场重新选择，不要无限追加重复行：

```sh
gentoo # emerge --ask --oneshot app-portage/mirrorselect
gentoo # mirrorselect --help
```

仓库同步在受限网络下继续用：

```sh
gentoo # emerge-webrsync
```

等永久代理稳定后再决定是否切回 `emerge --sync`。Distfiles、ebuild repository 和
binary package 是三条不同下载通道；只设置 `GENTOO_MIRRORS` 不会自动替换所有通道。

### 13.2 先恢复 Mihomo，但先不开 TUN

不要假定 Gentoo 主仓库一定提供当前 Mihomo 版本。第一阶段直接安装已经校验的上游
amd64 二进制到 `/usr/local/bin/mihomo`，并保存来源、版本、SHA256。以后再决定用
正式 ebuild/overlay 管理。

恢复：

- `/etc/mihomo/config.yaml`，mode `0600`
- provider 文件
- GeoIP/GeoSite
- controller 选择状态

第一次启动仍把 `tun.enable` 设为 `false`，先运行语法检查：

```sh
gentoo # /usr/local/bin/mihomo -t \
  -d /var/lib/mihomo -f /etc/mihomo/config.yaml
```

创建 `/etc/init.d/mihomo`：

```sh
#!/sbin/openrc-run

name="mihomo"
description="Mihomo local proxy"
command="/usr/local/bin/mihomo"
command_args="-d /var/lib/mihomo -f /etc/mihomo/config.yaml"
supervisor="supervise-daemon"
respawn_delay=3
respawn_max=0

depend() {
    need net
    after NetworkManager
    use logger
}
```

Mihomo 的 TUN/路由管理需要网络管理能力。第一阶段让此服务以 root 运行，配置只允许
root 读取；稳定后再评估 dedicated user + Linux capabilities，不在重装当天同时引入
额外权限变量。

```sh
gentoo # install -d -m 700 /etc/mihomo /var/lib/mihomo
gentoo # chmod 600 /etc/mihomo/config.yaml
gentoo # chmod 755 /etc/init.d/mihomo
gentoo # rc-update add mihomo default
```

用 OpenRC service 启动后，先验证 mixed-port：

```sh
gentoo # rc-service mihomo start
gentoo # ss -lntp | grep -E ':7890|:9090'
gentoo # curl --proxy http://127.0.0.1:7890 \
  -I --max-time 20 https://distfiles.gentoo.org/
```

OpenRC 服务要求：

- `need net`
- `after NetworkManager`
- 失败后约 3 秒重启
- 配置目录 `0700`、配置 `0600`
- controller 和 mixed-port 默认只对本机开放
- 日志可通过 syslog 或独立日志读取

只有在本地 LAN SSH 已验证并保留第二会话后，才开启 TUN：

1. 保留 `10.0.0.0/8`、`100.64.0.0/10`、`127.0.0.0/8`、
   `169.254.0.0/16`、`172.16.0.0/12`、`192.168.0.0/16`、
   `fc00::/7`、`fe80::/10` 直连。
2. 保留 CN、private 和 Codeberg 直连意图。
3. 开启 `tun.enable`、auto-route、auto-detect-interface 和 DNS hijack。
4. 启动后立即验证 SSH 第二会话、DNS、IPv4、IPv6、国内站点和外部站点。
5. 若第二 SSH 会话失败，第一会话立刻关闭 TUN，而不是重启网络。

Portage 临时使用环境变量：

```sh
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=socks5h://127.0.0.1:7890
export no_proxy=localhost,127.0.0.1,::1
```

不要把订阅 URL 或认证信息放进 `/etc/profile`、Bash history 或本仓库。

## 14. 挂载 2TB，但保持新 home 独立

### 14.1 固定基准挂载

先只读检查：

```sh
gentoo # install -d -m 755 /mnt/storage/old-home /data/media
gentoo # mount -o ro \
  UUID=e6ea7aa4-834f-47c0-8843-8a4ff88d3a55 \
  /mnt/storage/old-home
gentoo # mount -o ro \
  UUID=fef36a86-961e-4148-a2c6-6e56ec9a707f \
  /data/media
gentoo # findmnt -T /mnt/storage/old-home
gentoo # findmnt -T /data/media
gentoo # ls -ldn /mnt/storage/old-home/yurikon /data/media
```

确认旧 home 中的用户数据 owner 为 UID 1000。媒体盘存在旧 Jellyfin UID/GID 956
时，不要把新用户或服务账号强行改成 956。

确认后卸载，写入 `/etc/fstab`。不要带入任何 `x-systemd.*` 选项：

```fstab
UUID=e6ea7aa4-834f-47c0-8843-8a4ff88d3a55  /mnt/storage/old-home  ext4  nofail,noatime  0 2
UUID=fef36a86-961e-4148-a2c6-6e56ec9a707f  /data/media            ext4  nofail,noatime  0 2
```

切换为 fstab 的读写挂载并复核：

```sh
gentoo # umount /data/media /mnt/storage/old-home
gentoo # mount -a
gentoo # findmnt -T /mnt/storage/old-home
gentoo # findmnt -T /data/media
gentoo # findmnt -no OPTIONS -T /mnt/storage/old-home
```

### 14.2 选择性链接；必要时才用 bind mount

本地新 home 保留：

- `~/.config`、`~/.local/bin`、`~/.ssh`、`~/.gnupg`
- `~/.cache`
- `~/Downloads`
- Gentoo dotfiles 和配置仓库

从旧 home 选择性复用：

- `Learning`
- `Documents`
- `Pictures`
- `Music`
- `Videos`
- `Mail`
- `Zotero`
- `.local/share/Steam`
- `.local/share/PrismLauncher`

本机推荐默认使用符号链接。理由是 2TB 缺失时链接会明确变成 dangling link，不会阻止
OpenRC 启动，也不会悄悄在 512GB 的同名空目录中生成第二份数据。

在安装会自动创建这些目录的应用之前建立链接。若目标已经存在，只允许删除已确认
为空的目录；非空时停止并人工合并：

```sh
gentoo # sudo -u yurikon ln -s \
  /mnt/storage/old-home/yurikon/Learning \
  /home/yurikon/Learning
gentoo # sudo -u yurikon ln -s \
  /mnt/storage/old-home/yurikon/Documents \
  /home/yurikon/Documents
gentoo # sudo -u yurikon ln -s \
  /mnt/storage/old-home/yurikon/Pictures \
  /home/yurikon/Pictures
gentoo # sudo -u yurikon ln -s \
  /mnt/storage/old-home/yurikon/Mail \
  /home/yurikon/Mail
```

Steam 和 PrismLauncher 只链接各自的子目录，不链接整个 `.local`：

```sh
gentoo # install -d -o yurikon -g users /home/yurikon/.local/share
gentoo # sudo -u yurikon ln -s \
  /mnt/storage/old-home/yurikon/.local/share/Steam \
  /home/yurikon/.local/share/Steam
gentoo # sudo -u yurikon ln -s \
  /mnt/storage/old-home/yurikon/.local/share/PrismLauncher \
  /home/yurikon/.local/share/PrismLauncher
```

验证：

```sh
gentoo # sudo -u yurikon test -w /home/yurikon/Learning
gentoo # sudo -u yurikon touch /home/yurikon/Learning/.gentoo-write-test
gentoo # rm /home/yurikon/Learning/.gentoo-write-test
gentoo # readlink -f /home/yurikon/Learning
```

仅当某个应用不能正确处理符号链接时，才为该单一目录使用 bind mount。不要把 bind
项直接堆进 fstab；创建 `/etc/local.d/20-old-home.start`，在确认 2TB 已挂载后执行：

```sh
#!/bin/sh

base=/mnt/storage/old-home/yurikon
home=/home/yurikon

mountpoint -q /mnt/storage/old-home || exit 0

bind_one() {
    source=$1
    target=$2
    [ -d "$source" ] || return 0
    mountpoint -q "$target" && return 0
    mount --bind "$source" "$target"
}

# 只在确有需要时取消注释：
# bind_one "$base/Mail" "$home/Mail"
```

脚本 mode 设为 `0755`，目标目录预先以 `yurikon:users` 创建，并确保 OpenRC 的
`local` service 已启用。这样 2TB 缺失时脚本退出 0：

```sh
gentoo # chmod 755 /etc/local.d/20-old-home.start
gentoo # rc-update add local default
```

### 14.3 媒体权限

新建共享组，例如 `media`，用 group + ACL 管理 `/data/media`：

```sh
gentoo # groupadd media
gentoo # usermod -aG media yurikon
```

安装 Jellyfin 后把其服务用户加入 `media`，再用 `setfacl` 授予所需目录权限。先备份
旧 ACL：

```sh
gentoo # getfacl -R /data/media > /root/data-media.acl.before
```

不要递归 `chown` 整个媒体盘，不要用 `chmod -R 777`。

### 检查点 STORAGE

- [ ] `/home/yurikon` 的 filesystem source 与 `/` 相同。
- [ ] 不挂 2TB 时 Bash、SSH、网络仍正常。
- [ ] 每个 bind source 来自预期旧 home。
- [ ] 写测试只以 UID 1000 用户完成。
- [ ] 媒体权限使用共享组/ACL，没有重用 UID 956。

## 15. Bash 快速上手环境

从 Nix 配置提取行为，不复制 Nix store 路径。目标文件：

- `~/.bash_profile`：只负责登录环境并 source `~/.bashrc`。
- `~/.bashrc`：交互配置。
- `~/.config/bash/aliases.bash`：alias。
- `~/.local/bin/`：普通 Bash/POSIX 脚本。

`~/.bash_profile` 最小内容：

```bash
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
```

`~/.bashrc` 至少保留：

- `~/.local/bin`、Cargo、npm 用户 bin 的 PATH。
- `e='emacsclient -n -c -a emacs'`
- `et='emacsclient -t -a emacs'`
- `..`、`...`、目录跳转和 reload alias。
- Yazi 的 `y()` cwd wrapper。
- Starship、Zoxide、fzf、direnv 的 Bash hook。
- sops 解密 hook 只输出到 `XDG_RUNTIME_DIR`，不长期 export 明文秘密。

建议安装：

```sh
gentoo # emerge --ask \
  app-shells/bash-completion app-shells/fzf app-shells/zoxide \
  app-shells/starship \
  sys-apps/ripgrep sys-apps/fd app-misc/jq app-misc/tmux \
  dev-vcs/git dev-vcs/git-lfs net-misc/openssh
```

Yazi 和 Direnv 当前不在 Gentoo 主仓库，而在 Gentoo 的 GURU 用户维护仓库。系统稳定
后再只为这两个包启用 GURU：

```sh
gentoo # emerge --ask app-eselect/eselect-repository
gentoo # eselect repository enable guru
gentoo # emaint sync -r guru
gentoo # emerge --pretend --verbose \
  app-misc/yazi::guru app-shells/direnv::guru
```

只对这两个 atom 接受现场要求的 keyword，审阅后安装；不要因为 GURU 而全局启用
`~amd64`。如果不希望引入 overlay，改用已校验的上游二进制放入
`/usr/local/bin`，并记录版本和 SHA256。

包 atom 若现场变化，先用 `emerge --search` 查实际名称。不要为保留 Fish 插件而重新
安装 Fish；只把仍有价值的行为改写成 Bash。

恢复 SSH client 配置时，把 Codeberg 专用 identity 保留下来，但私钥只能来自加密
备份。`~/.ssh/config` 对应段：

```sshconfig
Host codeberg.org
    HostName codeberg.org
    User git
    IdentityFile ~/.ssh/id_ed25519_codeberg
    IdentitiesOnly yes
```

修复并验证权限：

```sh
yurikon $ chmod 700 ~/.ssh
yurikon $ chmod 600 ~/.ssh/config ~/.ssh/id_ed25519_codeberg
yurikon $ ssh -G codeberg.org | grep -Ei 'hostname|user|identityfile|identitiesonly'
yurikon $ ssh -T git@codeberg.org
```

第一次连接前核对 host key 来源；不要为了消除提示关闭
`StrictHostKeyChecking`。GitHub、macOS、GPU 主机和其他 alias 依照当前
`modules/home/cli/ssh.nix` 逐项转写，不能把 Nix 生成结果中的 store 路径照搬。

验收：

```sh
yurikon $ echo "$SHELL"
yurikon $ getent passwd "$USER"
yurikon $ bash -l
yurikon $ command -v git rg fd yazi emacsclient
yurikon $ direnv version
```

## 16. Sway 最小闭环

### 16.1 先安装会话基础

OpenRC 使用 `elogind` 提供 session、seat 和 `XDG_RUNTIME_DIR`。先确认 desktop
profile 的 USE 结果，再安装：

```sh
gentoo # emerge --pretend --verbose \
  sys-auth/elogind sys-auth/polkit \
  gnome-extra/polkit-gnome \
  gui-wm/sway gui-libs/greetd gui-apps/tuigreet \
  gui-apps/swaybg gui-apps/swayidle gui-apps/swaylock \
  gui-apps/waybar gui-apps/mako gui-apps/fuzzel \
  gui-apps/wl-clipboard gui-apps/grim gui-apps/slurp \
  gui-apps/swappy x11-terms/alacritty \
  sys-apps/xdg-desktop-portal sys-apps/xdg-desktop-portal-gtk \
  gui-libs/xdg-desktop-portal-wlr
```

审阅无误后再 `emerge --ask` 同一列表。稳定 Sway 当前优先，不为追最新版本全局启用
`~amd64`。

启用基础服务：

```sh
gentoo # rc-update add elogind boot
```

Polkit daemon 由 system D-Bus 激活，不添加不存在的 `polkit` OpenRC service；
Sway session 中启动 `polkit-gnome-authentication-agent-1`。

先不要启用 greetd。TTY 登录为 `yurikon` 后手动测试：

```sh
yurikon $ /usr/local/bin/start-sway-intel
```

这个包装器必须已经按第 10.5 节创建；它确保 Sway 不因 DRM 编号变化而误用 RTX
2050。

### 16.2 恢复配置的顺序

从当前 Nix 工作树提取：

```text
/home/yurikon/nixos-config/modules/home/desktop/sway/config
/home/yurikon/nixos-config/modules/home/desktop/sway.nix
/home/yurikon/nixos-config/modules/home/desktop/lockscreen.nix
```

迁移到原生文件时：

1. 先放最小 `~/.config/sway/config`：终端、退出、启动器。
2. 删除所有 `/nix/store/...` 路径和 Nix `${...}` 注入。
3. 把 `close-sway-window`、电源菜单、蓝牙菜单、OSD、壁纸脚本落到
   `~/.local/bin`。
4. 用 `swaymsg -t get_outputs` 和 `swaymsg -t get_inputs` 重建输出与输入配置。
5. 不假定输出仍叫 `DP-1`、`eDP-1`。
6. 再恢复 Waybar、Mako、Fuzzel、Kanshi、Fcitx5、Cliphist、Wob、Udiskie。

`ecf1ba0` 中已经确认的行为也必须保留：

- docked profile 同时启用外屏和内屏；外屏位于左侧，内屏位于其右侧。
- 当前参考值为外屏 2560×1440@165Hz、scale 1.25、position `0,0`；内屏
  2560×1600@120Hz、scale 1.6、position `2048,0`。安装后用实际输出名复核。
- `$mod+Ctrl+方向键/hjkl` 聚焦物理输出，
  `$mod+Ctrl+Shift+方向键/hjkl` 把整个 workspace 移到另一输出。
- `$mod+Tab`/`$mod+Shift+Tab` 使用 `next_on_output`/`prev_on_output`。
- Workstyle 会修改完整 workspace 名，因此数字快捷键继续使用 `workspace number N`。
- 键盘保持标准 US 布局，不恢复已经删除的 `ctrl:nocaps`。

最小验收通过后配置 `/etc/greetd/config.toml`：

```toml
[terminal]
vt = 1

[default_session]
command = "/usr/bin/tuigreet --time --remember --cmd /usr/local/bin/start-sway-intel"
user = "greeter"
```

确认 `greeter` 用户、VT 和三个实际命令路径；若现场路径不同，在 TOML 中替换为
`command -v` 返回的绝对路径。然后：

```sh
gentoo # rc-update add greetd default
gentoo # rc-service greetd start
```

远程执行 `rc-service greetd start` 前保留 SSH 会话；greetd 失败不应影响 SSH。

### 16.3 PipeWire 和会话组件

安装：

```sh
gentoo # emerge --pretend --verbose \
  media-video/pipewire media-video/wireplumber
gentoo # emerge --ask media-video/pipewire media-video/wireplumber
```

确认 PipeWire 启用了所需的 `sound-server`、`pipewire-alsa`、`pulseaudio`、
`bluetooth`、`elogind` 和 multilib 能力。以安装后的：

```sh
man gentoo-pipewire-launcher
```

为准，把 `gentoo-pipewire-launcher` 在 Sway session 中只启动一次。不要同时启动
PulseAudio daemon。

当前 systemd user units 不能直接复制。快速恢复阶段可用一个幂等
`~/.local/bin/sway-session-start` 启动：

- `gentoo-pipewire-launcher`
- Mako
- Waybar
- Fcitx5
- Kanshi
- Workstyle
- Cliphist watcher
- Wob
- Udiskie
- Polkit agent
- swayidle/锁屏

脚本对每个进程先检查是否已运行，避免 `sway reload` 重复启动。

稳定后改用 OpenRC 0.60+ user services：

- 用户脚本放 `/etc/user/init.d/`
- 用户配置放 `/etc/user/conf.d/`
- `rc-update --user add <service>`
- 需要开机常驻时链接 `/etc/init.d/user.yurikon -> /etc/init.d/user`，再
  `rc-update add user.yurikon`

Emacs、mbsync、rclone 不应跟随 Sway 退出；Waybar、Mako、swayidle 等应跟随图形会话。

### 16.4 Sway 验收

- [ ] TTY 手动启动 Sway 成功后才启用 greetd。
- [ ] Sway 固定使用 Intel/i915；Mesa Intel、Vulkan 和 XWayland 正常。
- [ ] 默认应用不唤醒 RTX 2050，`prime-run` 能按需使用 NVIDIA。
- [ ] 单屏、外接屏、合盖、亮度、音量按键正常。
- [ ] Alacritty、Fuzzel、Waybar、Mako 正常。
- [ ] Fcitx5 在 GTK、Qt、Emacs 中可输入中文。
- [ ] portal 文件选择和屏幕共享正常。
- [ ] 截图保存到 `~/Pictures/Screenshots`。
- [ ] swaylock 和 suspend 后解锁正常。
- [ ] `sway reload` 不产生重复进程。

## 17. Emacs 恢复

### 17.1 先选择稳定版本

截至 2026-07-29，Gentoo amd64 的 Emacs 31.0.90 仍是 `~amd64`，稳定版本为 Emacs
30.2。为了先恢复工作能力：

1. 首先安装稳定 Emacs 30.2 PGTK。
2. 验证当前 init 是否兼容。
3. 整体系统稳定后，再为 `app-editors/emacs` 单独接受 Emacs 31 的 `~amd64`。
4. 不全局启用 `ACCEPT_KEYWORDS="~amd64"`。

`/etc/portage/package.use/emacs` 建议：

```text
app-editors/emacs gui gtk -X cairo dbus gfile gmp harfbuzz json libxml2 sqlite ssl svg tree-sitter xattr
net-mail/mu emacs
```

`gui gtk -X` 表达纯 GTK/Wayland PGTK 方向。现场先运行：

```sh
gentoo # emerge --pretend --verbose app-editors/emacs
```

再安装：

```sh
gentoo # emerge --ask \
  app-editors/emacs app-emacs/emacs-daemon app-emacs/emacs-openrc \
  net-mail/mu net-mail/isync mail-mta/msmtp \
  app-text/poppler app-text/texlive dev-texlive/texlive-langchinese
```

包 atom 和 USE flag 以当前 Portage 输出为准。Mermaid CLI、Tree-sitter grammar、语言
服务器和项目编译器不要无差别全局安装；按现有 init 的实际外部命令补齐。

### 17.2 配置与数据

必须迁移：

- `modules/home/development/emacs/init.el`
- `modules/home/development/emacs/early-init.el`
- 兼容 loader `~/.emacs`
- `~/Learning/org-learning`
- Org-roam 数据和必要数据库；数据库可重建时优先重建
- `~/Mail` 的 Maildir
- `~/Zotero`

必须改写：

- Nix 注入的 `mmdc`、`wl-copy` 和其他 `/nix/store` 路径。
- Nix 管理的 Elisp package load-path。
- systemd user socket/service。
- Emacs daemon 的环境变量；保留清空 `GTK_IM_MODULE` 的现有意图，并重新测试
  Fcitx/Emacs PGTK。

先不启动 daemon：

```sh
yurikon $ emacs -Q
yurikon $ emacs --debug-init
```

再测试：

- Org 和 Org-roam
- mu4e
- Tree-sitter
- PDF tools
- Mermaid
- CTeX/XeLaTeX 中文 Org 导出
- `wl-copy`/`wl-paste`

中文 PDF 导出前单独验证工具链，缺一项就先修复 TeX 包，不修改 Elisp 绕过：

```sh
yurikon $ command -v xelatex latexmk
yurikon $ kpsewhich ctexart.cls
yurikon $ kpsewhich FandolSong-Regular.otf
```

最后用 Gentoo 提供的 `emacs-openrc`/`emacs-daemon` 作为参考，建立 OpenRC user
service。目标是：

```sh
yurikon $ emacsclient -n -c -a emacs
yurikon $ emacsclient -t -a emacs
```

在没有 Sway 的 SSH/TTY 会话中，TTY client 也应可用。

## 18. 系统服务恢复顺序

不要一次性启用所有服务。每组完成配置、权限和验证后再加入 runlevel。

### P0：已经完成

- NetworkManager
- OpenSSH
- syslog
- Chrony
- Cronie
- Mihomo mixed-port；TUN 在 SSH 验证后开启

### P1：桌面闭环

- DBus、elogind、Polkit
- greetd/tuigreet
- PipeWire/WirePlumber
- Bluetooth/Blueman
- UDisks/GVfs/Udiskie
- UPower、电源策略
- CUPS/Avahi、SANE

### P2：网络和开发服务

- Tailscale：优先重新认证；只有确实需要保留节点身份时才恢复
  `/var/lib/tailscale`。
- Docker：安装但不加入 default runlevel，保留“手动启动”语义。
- libvirt：安装后再创建用户组和网络；旧盘点没有 VM/pool/network，不迁移空状态。
- Flatpak：安装 portal 后再添加 Flathub。
- usbmuxd：恢复 pairing records 前确认 owner 和权限。

### P3：数据型服务

- Jellyfin：默认不自启；服务用户加入 `media` 组，只授予需要的媒体目录。
- rclone：默认不自启；配置和 OAuth token 从加密备份恢复。
- Mail：mbsync 每 10 分钟，失败日志可见；不要跟 Sway 生命周期绑定。

服务策略表：

| 服务 | OpenRC 策略 | 首次启用前验证 |
| --- | --- | --- |
| SSH | `default` | 公钥、host key、防火墙、第二会话 |
| NetworkManager | `default` | 有线/Wi-Fi、DNS、单一网络栈 |
| Mihomo | 网络后自动 | mixed-port、TUN、DNS、LAN/Tailscale 直连 |
| Tailscale | `default` | 登录状态、路由、与 Mihomo 共存 |
| Docker | 手动 | daemon proxy、组权限、无遗留容器假设 |
| libvirt | 按需或 default | KVM Intel、用户组、网络 |
| Jellyfin | 手动 | media ACL、数据库、端口 |
| rclone | 用户手动 | token、FUSE、卸载脚本 |
| Emacs daemon | OpenRC user service | 环境、socket/client |
| mbsync | cron/user service | 凭据命令、Maildir、mu index |

防火墙最后配置。先明确允许当前 LAN 的 SSH，再启用规则；每次变更保留已连接的 SSH
会话并用第二会话测试。

## 19. Swap、zram 与内存压力

不要复用旧 2TB `/home/.swapfile`。新 swap 必须在 512GB 根文件系统上。

基础系统完全稳定后再创建，例如 16 GiB：

```sh
gentoo # fallocate -l 16G /swapfile
gentoo # chmod 600 /swapfile
gentoo # mkswap /swapfile
gentoo # swapon /swapfile
```

fstab：

```fstab
/swapfile none swap defaults,pri=10 0 0
```

zram 目标保持原意：

- zstd
- 容量约 RAM 的 25%
- priority 100
- `vm.swappiness=20`

OpenRC 下使用当前 Gentoo 提供的 zram init 包/脚本，不复制 NixOS 生成配置。
systemd-oomd 不迁移；先观察内存压力，再选择 earlyoom 或其他 OpenRC 方案。

## 20. 每日维护和配置管理

Gentoo 配置建议至少纳入一个仅本机可见或私有 Git 仓库：

- `/etc/portage`
- `/etc/conf.d` 中的自定义服务配置
- 自写 `/etc/init.d` 和 `/etc/user/init.d`
- `/etc/local.d`
- Bash、Sway、Emacs 和其他 dotfiles

不要提交：

- `/etc/mihomo/config.yaml` 的订阅和节点
- NetworkManager keyfiles
- SSH host/private keys
- Tailscale state
- rclone、邮箱、浏览器 token
- 运行数据库、缓存和日志

常规更新：

```sh
gentoo # emerge-webrsync
gentoo # emerge --ask --verbose --update --deep --newuse @world
gentoo # emerge --ask --depclean
gentoo # revdep-rebuild
```

`revdep-rebuild` 由 `app-portage/gentoolkit` 提供。每次先读 news、审阅计划和配置文件
更新，不盲目覆盖 `/etc`。

## 21. 最终验收与回滚门槛

### 21.1 基础和远程

- [ ] 连续三次冷启动进入 Gentoo。
- [ ] 每次均能从 LAN SSH 登录。
- [ ] LiveUSB 可以进入救援环境。
- [ ] `bootctl list` 至少保留一个可工作的旧 Gentoo kernel。
- [ ] SSH host key 指纹有离线记录。
- [ ] root 不能远程登录。

### 21.2 网络

- [ ] 直连国内镜像可下载 Stage/Distfiles。
- [ ] `emerge-webrsync` 可用。
- [ ] Mihomo mixed-port 和 TUN 分别通过测试。
- [ ] TUN 开启后 LAN SSH 不断。
- [ ] Tailscale peer 可达，100.64.0.0/10 不被代理。
- [ ] 国内、外部、IPv4、IPv6、DNS 均按策略工作。

### 21.3 存储

- [ ] 新 home 与 `/` 位于 Micron 512GB 根文件系统。
- [ ] 2TB 两个原 UUID 均未变化。
- [ ] 不接 2TB 仍能启动、SSH、Bash 和最小 Sway。
- [ ] Learning、Documents、Pictures、Mail 等 bind source 正确。
- [ ] Steam/PrismLauncher 只 bind 自己的子目录。
- [ ] Jellyfin/media 使用 group + ACL，没有 `777`。

### 21.4 工作环境

- [ ] Bash 登录、PATH、alias、Yazi、Starship、Zoxide、fzf、direnv 正常。
- [ ] Sway 双屏/单屏、输入法、通知、状态栏、portal、锁屏、截图正常。
- [ ] Emacs PGTK、daemon/client、Org/roam、mu4e、PDF、Mermaid、CTeX 正常。
- [ ] Mail 每 10 分钟同步，失败可见。
- [ ] Docker、Jellyfin、rclone 仍保持默认不自动启动。

### 21.5 何时可以清理备份

只有以下全部成立才考虑清理旧系统备份：

1. 上述所有验收完成。
2. 不可替代数据抽样校验通过。
3. 加密秘密已验证能解密和登录。
4. 至少保留一份与 2TB 物理独立的备份。
5. Gentoo 已稳定使用至少一周并完成一次 kernel/world 更新。

即使如此，也保留 `nixos-config` 的完整工作树和本迁移仓库作为长期参考。

## 22. 故障恢复速查

### SSH-LIVE 断线

1. 从管理端重连相同 Live IP。
2. `screen -r gentoo-install`。
3. 若 IP 变化，现场用 `ip -br addr` 查看。
4. 不要因为断线重新格式化或重复解压 Stage 3。

### chroot 后退出或机器重启

重新挂载 root、ESP、proc/sys/dev/run，然后 chroot。不要重新 `mkfs`。

### 第一次 Gentoo 无法启动

1. 从 LiveUSB 以 UEFI 模式启动。
2. 挂载 Micron part2 到 `/mnt/gentoo`。
3. 挂载 ESP 到 `/mnt/gentoo/boot`。
4. bind proc/sys/dev/run 并 chroot。
5. 检查 `/etc/fstab`、`/etc/kernel/cmdline`、initramfs 和 `bootctl list`。
6. 用 `emerge --config sys-kernel/gentoo-kernel-bin` 重建 initramfs/引导项。

### Gentoo 能启动但 SSH 不通

本地控制台检查：

```sh
rc-service NetworkManager status
rc-service sshd status
ip -br addr
ip route
ss -lntp | grep ':22'
sshd -t
tail -n 200 /var/log/rc.log
```

### 开启 Mihomo TUN 后 SSH 断线

1. 本地控制台或保留的第一会话关闭 TUN。
2. 确认 LAN 和 `100.64.0.0/10` 直连规则。
3. 检查 auto-detect-interface、默认路由和 DNS hijack。
4. mixed-port 模式稳定前不要再次开 TUN。

### 2TB 缺失导致启动或 home 异常

1. 从 fstab 临时注释 bind 项，只保留 `nofail` 基准挂载。
2. 确认 `/home/yurikon` 仍是本地普通目录。
3. 把 bind 逻辑迁到带 source/mountpoint 检查的 `/etc/local.d` 脚本。

## 23. 只需要补看的官方资料

执行过程中若命令与现场版本不一致，只优先补看这些官方页面：

- [Gentoo amd64 Handbook：完整安装](https://wiki.gentoo.org/wiki/Handbook%3AParts/Full/Installation)
- [Gentoo Handbook：基本系统与 binary packages](https://wiki.gentoo.org/wiki/Handbook%3AParts/Installation/Base/en)
- [Gentoo OpenRC](https://wiki.gentoo.org/wiki/OpenRC)
- [Gentoo NetworkManager](https://wiki.gentoo.org/wiki/NetworkManager)
- [Gentoo mirror status](https://mirrorstats.gentoo.org/releases/)
- [Gentoo Intel Graphics](https://wiki.gentoo.org/wiki/Intel_Graphics)
- [Gentoo NVIDIA driver](https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers)
- [Gentoo Sway](https://wiki.gentoo.org/wiki/Sway)
- [Gentoo PipeWire](https://wiki.gentoo.org/wiki/PipeWire)
- [Gentoo package database](https://packages.gentoo.org/)
- [NVIDIA PRIME Render Offload](https://download.nvidia.com/XFree86/Linux-x86_64/455.45.01/README/primerenderoffload.html)
- [NVIDIA Runtime D3 Power Management](https://download.nvidia.com/XFree86/Linux-x86_64/460.39/README/dynamicpowermanagement.html)

本手册已经把与当前机器直接相关的磁盘、SSH、存储、代理、Bash、Sway、Emacs 和服务
顺序确定下来；Handbook 主要用于核对安装当天的 Stage 3 文件名、profile、包版本和
USE flag。
