#!/usr/bin/env bash

set -euo pipefail
umask 077

readonly MOMONGA_ROOT=/run/media/yurikon/Momonga
readonly AGE_RECIPIENT=age13jwmkdne8smsj2wenz4nj0fmmc0d0rf9mf783hmuhhmr927nsgrq8maluy
readonly AGE_BIN=/etc/profiles/per-user/yurikon/bin/age

if (( EUID != 0 )); then
  echo "This helper must run as root." >&2
  exit 1
fi

if (( $# != 1 )); then
  echo "Usage: $0 BACKUP_DIRECTORY" >&2
  exit 1
fi

backup_root=$1
case "$backup_root" in
  "$MOMONGA_ROOT"/MyData/Gentoo-Migration-*)
    ;;
  *)
    echo "Refusing unexpected backup path: $backup_root" >&2
    exit 1
    ;;
esac

if [[ ! -d $backup_root/archives || ! -d $backup_root/inventory ]]; then
  echo "The unprivileged backup stage has not prepared $backup_root." >&2
  exit 1
fi

if [[ ! -x $AGE_BIN ]]; then
  echo "age is not executable at $AGE_BIN." >&2
  exit 1
fi

findmnt -T "$MOMONGA_ROOT" -o UUID,FSTYPE -n > "$backup_root/inventory/momonga-filesystem-root.txt"
blkid > "$backup_root/inventory/blkid-root.txt"
efibootmgr -v > "$backup_root/inventory/efibootmgr-root.txt" 2>&1 || true

readonly -a requested_paths=(
  /boot
  /etc/NetworkManager
  /var/lib/NetworkManager
  /etc/mihomo
  /var/lib/mihomo
  /var/lib/private/mihomo
  /etc/ssh
  /var/lib/tailscale
  /var/lib/bluetooth
  /var/lib/lockdown
  /etc/jellyfin
  /var/lib/jellyfin
  /var/cache/jellyfin
  /etc/cups
  /var/spool/cups
)

declare -a existing_paths=()
: > "$backup_root/inventory/system-state-paths.txt"
for source_path in "${requested_paths[@]}"; do
  if [[ -e $source_path ]]; then
    existing_paths+=("$source_path")
    printf 'included\t%s\n' "$source_path" \
      >> "$backup_root/inventory/system-state-paths.txt"
  else
    printf 'missing\t%s\n' "$source_path" \
      >> "$backup_root/inventory/system-state-paths.txt"
  fi
done

if (( ${#existing_paths[@]} == 0 )); then
  echo "No system-state paths were found." >&2
  exit 1
fi

tar --acls --xattrs --numeric-owner --one-file-system \
  -cpf - "${existing_paths[@]}" \
  | "$AGE_BIN" -r "$AGE_RECIPIENT" \
      -o "$backup_root/archives/system-state.tar.age"

echo "Privileged system state was archived and age-encrypted."
