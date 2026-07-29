#!/usr/bin/env bash

set -euo pipefail
umask 077

readonly MOMONGA_ROOT=/run/media/yurikon/Momonga
readonly EXPECTED_UUID=EB7F-5025
readonly EXPECTED_FSTYPE=exfat
readonly REPO_ROOT=/home/yurikon/nixos-to-gentoo
readonly DEFAULT_BACKUP_ROOT=$MOMONGA_ROOT/MyData/Gentoo-Migration-20260729-final

backup_root=${1:-$DEFAULT_BACKUP_ROOT}

case "$backup_root" in
  "$MOMONGA_ROOT"/MyData/Gentoo-Migration-*)
    ;;
  *)
    echo "Refusing unexpected backup path: $backup_root" >&2
    exit 1
    ;;
esac

read -r target_uuid target_fstype < <(
  findmnt -T "$MOMONGA_ROOT" -o UUID,FSTYPE -n
)
if [[ $target_uuid != "$EXPECTED_UUID" || $target_fstype != "$EXPECTED_FSTYPE" ]]; then
  printf 'Unexpected target filesystem: UUID=%s FSTYPE=%s\n' \
    "$target_uuid" "$target_fstype" >&2
  exit 1
fi

if [[ -e $backup_root ]]; then
  echo "Refusing to overwrite existing path: $backup_root" >&2
  exit 1
fi

available_bytes=$(df -B1 --output=avail "$MOMONGA_ROOT" | tail -n 1)
if (( available_bytes < 1073741824 )); then
  echo "Less than 1 GiB is available on Momonga." >&2
  exit 1
fi

install -d -m 0700 \
  "$backup_root/archives" \
  "$backup_root/docs" \
  "$backup_root/inventory" \
  "$backup_root/repositories"

cp "$REPO_ROOT/docs/gentoo-migration-checklist.md" \
  "$REPO_ROOT/docs/gentoo-remote-reinstall-runbook.md" \
  "$backup_root/docs/"

lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL \
  > "$backup_root/inventory/lsblk.txt"
findmnt -R -o TARGET,SOURCE,FSTYPE,OPTIONS \
  > "$backup_root/inventory/findmnt.txt"
df -hT > "$backup_root/inventory/df.txt"
id > "$backup_root/inventory/id.txt"
getent group > "$backup_root/inventory/groups.txt"
uname -a > "$backup_root/inventory/uname.txt"
nixos-version > "$backup_root/inventory/nixos-version.txt"
lspci -nnk > "$backup_root/inventory/lspci-nnk.txt"
lsusb > "$backup_root/inventory/lsusb.txt"
ip -brief address > "$backup_root/inventory/ip-address.txt"
ip route show table all > "$backup_root/inventory/ip-route.txt"
systemctl list-unit-files --no-pager \
  > "$backup_root/inventory/systemd-unit-files.txt"
systemctl list-units --all --no-pager \
  > "$backup_root/inventory/systemd-units.txt"
flatpak list --columns=application,branch,origin \
  > "$backup_root/inventory/flatpak-apps.txt" 2>&1 || true

readonly -a repositories=(
  nixos-config
  nixos-to-gentoo
  nixos-config-macos
)

for repository in "${repositories[@]}"; do
  repository_path=/home/yurikon/$repository
  if ! git -C "$repository_path" rev-parse --git-dir > /dev/null 2>&1; then
    echo "Missing Git repository: $repository_path" >&2
    exit 1
  fi

  git -C "$repository_path" status --short --branch \
    > "$backup_root/repositories/$repository.status.txt"
  git -C "$repository_path" rev-parse HEAD \
    > "$backup_root/repositories/$repository.head.txt"
  git -C "$repository_path" diff --binary \
    > "$backup_root/repositories/$repository.worktree.patch"
  git -C "$repository_path" diff --cached --binary \
    > "$backup_root/repositories/$repository.index.patch"
  git -C "$repository_path" bundle create \
    "$backup_root/repositories/$repository.bundle" --all
  git -C "$repository_path" bundle verify \
    "$backup_root/repositories/$repository.bundle"
done

tar --acls --xattrs --numeric-owner -cpf \
  "$backup_root/archives/config-repositories.tar" \
  -C /home/yurikon "${repositories[@]}"

pkexec "$REPO_ROOT/scripts/backup-gentoo-migration-root.sh" "$backup_root"

checksum_tmp=$(mktemp)
trap 'rm -f "$checksum_tmp"' EXIT
(
  cd "$backup_root"
  find . -type f ! -name SHA256SUMS -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 sha256sum > "$checksum_tmp"
  cp "$checksum_tmp" SHA256SUMS
  sha256sum --check SHA256SUMS
)

sync
printf 'Backup completed: %s\n' "$backup_root"
