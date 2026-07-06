# Repository Guidelines

## Project Structure & Module Organization

This repository worktree is a macOS nix-darwin flake for user `yurikon`.
It also keeps standalone Home Manager outputs for user-layer evaluation.

Main entry points:

- `flake.nix`: flake inputs, `darwinConfigurations`, and `homeConfigurations`.
- `hosts/macos/default.nix`: host-specific nix-darwin entry.
- `hosts/macos/home.nix`: Home Manager entry for user `yurikon`.
- `home.nix`: compatibility shim importing `hosts/macos/home.nix`.
- `modules/darwin/profiles/macos.nix`: macOS nix-darwin profile.
- `modules/home/profiles/macos.nix`: macOS Home Manager profile.

Reusable nix-darwin modules live under `modules/darwin/`:

- `core/` for Nix daemon and macOS defaults.
- `apps/` for Homebrew and system-level app management.
- `profiles/` for module composition.

Reusable Home Manager modules live under `modules/home/`:

- `core/` for session, shell, and XDG defaults.
- `cli/` for terminal and command-line workflows.
- `development/` for Emacs and common development tools.
- `desktop/fonts.nix` for user fonts and fontconfig.
- `profiles/` for module composition.

There are no traditional source, asset, or test directories. Treat Nix modules
as the project source.

## Build, Test, and Development Commands

- `nix flake check --no-build path:/home/yurikon/nixos-config-macos`: evaluate the flake without building.
- `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake path:$PWD#yurikon-macos`: first nix-darwin apply on Apple Silicon macOS.
- `sudo darwin-rebuild switch --flake path:$PWD#yurikon-macos`: subsequent Apple Silicon applies.
- `sudo darwin-rebuild switch --flake path:$PWD#yurikon-macos-x86_64`: Intel macOS apply.
- `nixfmt flake.nix home.nix hosts/**/*.nix modules/**/*.nix`: format Nix files.

Use the `path:` flake form while new files are untracked; plain Git-backed
flakes can miss untracked modules.

## Coding Style & Naming Conventions

Use `nixfmt` formatting. Keep modules small and named by responsibility, for
example `cli/git.nix`, `development/emacs.nix`, or `desktop/fonts.nix`. Avoid
vague names such as `misc.nix`.

Darwin modules should expose `myDarwin.*.enable`. Home Manager modules should
expose `myHome.*.enable`. Profiles should compose and enable modules, not
contain large implementation blocks.

Prefer structured nix-darwin and Home Manager options such as `homebrew.*`,
`system.defaults.*`, `programs.*`, `services.*`, `xdg.configFile`, and
`home.file` over ad hoc activation scripts.

## Testing Guidelines

There is no separate test framework. The required check is Nix evaluation:

```sh
nix flake check --no-build path:/home/yurikon/nixos-config-macos
```

For risky package changes, prefer `home-manager build` or a dry evaluation
before switching.

## Commit & Pull Request Guidelines

Keep commits concise and focused on one logical change.

For pull requests or review notes, include:

- What changed and why.
- Whether `nix flake check --no-build ...` passed.
- Any manual validation needed after switching on macOS.

## Security & Configuration Tips

Never commit private keys, tokens, cookies, password stores, browser sessions,
generated databases, caches, logs, or secret values. Browser state is explicitly
out of scope for this macOS worktree.

Project-specific LSPs, compilers, SDKs, and formatters should usually live in
each project's flake or dev shell, not in global Home Manager.
