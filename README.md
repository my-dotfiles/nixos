# NixOS Configuration

This repository is the declarative configuration for Yurikon's NixOS
workstation. It manages both system-level NixOS configuration and user-level
Home Manager configuration from one flake.

The current machine was migrated from Arch Linux. The backup used during the
migration lives outside this repository at:

```text
/run/media/yurikon/Momonga/MyData/Backup/nixos-migration-2026-05-28/
```

Use the backup as reference material only. Do not copy runtime state, caches,
tokens, private keys, browser sessions, or generated databases into this repo.

## Entry Points

```text
flake.nix                   Flake inputs and nixosConfigurations.nixos.
hosts/nixos/default.nix     Host entry for this machine.
home.nix                    Home Manager user entry for yurikon.
configuration.nix           Compatibility shim that imports hosts/nixos.
hardware-configuration.nix  Generated hardware and filesystem config.
```

The canonical system entry is `hosts/nixos/default.nix`. The root
`configuration.nix` is kept so the layout still looks familiar after migrating
from `/etc/nixos`, but new system configuration should usually go under
`modules/system`.

## Directory Layout

```text
hosts/
  nixos/             Per-host imports and host-only values.

modules/
  system/
    core/            Boot, Nix settings, locale, users, base packages.
    desktop/         System integration for desktop sessions.
    services/        System services such as PipeWire, OpenSSH, printing.
    profiles/        System module bundles.

  home/
    core/            XDG, shell/session, stable user defaults.
    cli/             Terminal tools and command-line workflow.
    desktop/         GUI apps, fonts, MIME, fcitx5, Niri config.
    development/     Editors and global development tools.
    secrets/         Hooks for local secret files; no secret values.
    profiles/        Home Manager module bundles.
```

## Applying Changes

Build and switch the full system, including Home Manager:

```sh
sudo nixos-rebuild switch --flake path:/home/yurikon/nixos-config#nixos
```

Check evaluation without building:

```sh
nix flake check --no-build path:/home/yurikon/nixos-config
```

Format Nix files:

```sh
nixfmt flake.nix home.nix configuration.nix hosts/**/*.nix modules/**/*.nix
```

The `path:` form is intentional while the worktree contains new untracked files.
Plain `nix flake check` uses the Git source view and can miss files that have
not been added to Git yet.

## System Configuration

System modules use the `mySystem.*` namespace and expose feature flags. A leaf
module should generally look like this:

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

Enable system features from `modules/system/profiles/workstation.nix`. Keep
host-only values such as `networking.hostName`, `system.stateVersion`, and
hardware imports in `hosts/nixos/default.nix`.

## Home Manager

Home modules use the `myHome.*` namespace. `home.nix` should stay small: it
sets the username, home directory, state version, and imports the workstation
profile.

Enable user features from `modules/home/profiles/workstation.nix`. Leaf modules
should prefer structured Home Manager options such as `programs.*`,
`services.*`, `xdg.configFile`, and `home.file`.

The global editor is Emacs. Project-specific language servers, compilers, and
formatters should normally be declared in each project's flake or dev shell.
Only common Nix and shell maintenance tools are installed globally.

## Desktop

The target desktop is Niri with Noctalia v5.

System-side Niri integration is in:

```text
modules/system/desktop/niri.nix
```

It enables Niri, GDM as the login manager, portal support, Wayland utilities,
power/bluetooth-related services, and installs Noctalia from the official v5
flake package:

```nix
inputs.noctalia.packages.${system}.default
```

User-side Niri configuration is in:

```text
modules/home/desktop/niri.nix
```

Niri starts Noctalia with the v5 command:

```kdl
spawn-at-startup "noctalia"
```

Noctalia is installed by Nix, but its user settings are not managed by Home
Manager. Configure Noctalia through its own UI or local config files.

GNOME Desktop is intentionally not enabled. GDM is kept only as the display
manager so the Niri session can be selected at login.

## Migration Rules

When migrating more files from the backup, classify them before adding them:

- System boot, users, services, hardware, networking: `modules/system`.
- Shell, terminal tools, editor config, user apps: `modules/home`.
- Machine-specific values and temporary host exceptions: `hosts/nixos`.
- Runtime state, caches, logs, sockets, histories: do not manage by default.
- Tokens, credentials, private keys, cookies, password stores: never commit.
- Project-specific LSPs, SDKs, compilers, and formatters: use project flakes.

Prefer semantic module names such as `cli/git.nix`, `desktop/fonts.nix`, or
`services/pipewire.nix`. Avoid catch-all names like `misc.nix`.

## Secrets

The `modules/home/secrets` area only describes how local secret files may be
sourced. It must not contain secret values.

Current local hooks look for:

```text
~/.config/secrets/api-keys.bash
~/.config/secrets/api-keys.fish
```

Those files are local machine state and should stay outside Git.

## Notes

`hardware-configuration.nix` is generated by `nixos-generate-config`. Keep it
small and hardware-specific. If a setting is a reusable policy rather than
hardware detection output, move it into a system module instead.
