# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for one NixOS workstation. The main entry points are:

- `flake.nix`: flake inputs and `nixosConfigurations.nixos`.
- `hosts/nixos/default.nix`: host-specific system entry.
- `home.nix`: Home Manager entry for user `yurikon`.
- `configuration.nix`: compatibility shim importing `hosts/nixos`.
- `hardware-configuration.nix`: generated hardware/filesystem configuration.

Reusable modules live under `modules/`:

- `modules/system/{core,desktop,services,profiles}` for NixOS options.
- `modules/home/{core,cli,desktop,development,secrets,profiles}` for Home Manager options.

There are no traditional source, asset, or test directories. Treat Nix modules as the project source.

## Build, Test, and Development Commands

- `nix flake check --no-build path:/home/yurikon/nixos-config`: evaluate the full flake without building.
- `sudo nixos-rebuild switch --flake path:/home/yurikon/nixos-config#nixos`: apply system and Home Manager changes.
- `nixfmt flake.nix home.nix configuration.nix hosts/**/*.nix modules/**/*.nix`: format Nix files.

Use the `path:` flake form while new files are untracked; plain Git-backed flakes can miss untracked modules.

## Coding Style & Naming Conventions

Use `nixfmt` formatting. Keep modules small and named by responsibility, for example `cli/git.nix`, `desktop/fonts.nix`, or `services/pipewire.nix`. Avoid vague names such as `misc.nix`.

System modules should expose `mySystem.*.enable`; Home Manager modules should expose `myHome.*.enable`. Profiles should compose and enable modules, not contain large implementation blocks.

Prefer structured options such as `programs.*`, `services.*`, `xdg.configFile`, and `home.file` over ad hoc activation scripts.

## Testing Guidelines

There is no separate test framework. The required check is Nix evaluation:

```sh
nix flake check --no-build path:/home/yurikon/nixos-config
```

For risky system changes, prefer a build or dry activation before switching. Verify Niri/Noctalia, fonts, input method, and shell behavior after desktop-related changes.

## Commit & Pull Request Guidelines

Recent commits use short summary messages, sometimes in Chinese, for example `use fish` or `调整 ghostty 字体`. Keep commits concise and focused on one logical change.

For pull requests or review notes, include:

- What changed and why.
- Whether `nix flake check --no-build ...` passed.
- Any manual validation needed after switching.
- Screenshots only for visible desktop/UI changes.

## Security & Configuration Tips

Never commit private keys, tokens, cookies, password stores, browser sessions, generated databases, caches, or logs. `modules/home/secrets` should only describe local hooks, not secret values.

Use the migration backup as reference material only. Project-specific LSPs, compilers, SDKs, and formatters should usually live in each project’s flake or dev shell, not in global Home Manager.
