{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.emacs;
  emacsPackages = pkgs.emacsPackagesFor pkgs.emacs-pgtk;
in
{
  options.myHome.development.emacs.enable = lib.mkEnableOption "Emacs configuration";

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = emacsPackages.emacsWithPackages (
        epkgs: with epkgs; [
          cape
          consult
          corfu
          corfu-terminal
          gruvbox-theme
          ef-themes
          magit
          marginalia
          markdown-mode
          nix-mode
          org-roam
          orderless
          (treesit-grammars.with-grammars (
            grammars: with grammars; [
              tree-sitter-bash
              tree-sitter-c
              tree-sitter-c-sharp
              tree-sitter-cmake
              tree-sitter-cpp
              tree-sitter-css
              tree-sitter-dockerfile
              tree-sitter-go
              tree-sitter-gomod
              tree-sitter-html
              tree-sitter-java
              tree-sitter-javascript
              tree-sitter-json
              tree-sitter-python
              tree-sitter-ruby
              tree-sitter-rust
              tree-sitter-toml
              tree-sitter-tsx
              tree-sitter-typescript
              tree-sitter-yaml
            ]
          ))
          vertico
          which-key
          htmlize

          avy
          embark
          embark-consult
          envrc
          rainbow-delimiters
          flycheck
          flycheck-package
          package-lint
          elsa
          helpful
          multiple-cursors

          tuareg
          ocaml-eglot

          yaml-mode

          nerd-icons
          nerd-icons-completion
          nerd-icons-dired

          kkp
        ]
      );
    };

    services.emacs = {
      enable = true;
      client.enable = true;
      socketActivation.enable = true;
      startWithUserSession = true;
    };

    systemd.user.services.emacs.Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    systemd.user.services.emacs.Service.Environment = [
      "GTK_IM_MODULE="
      "QT_IM_MODULE=fcitx"
      "XMODIFIERS=@im=fcitx"
      "INPUT_METHOD=fcitx"
      "SDL_IM_MODULE=fcitx"
      "LANG=zh_CN.UTF-8"
      "LC_CTYPE=zh_CN.UTF-8"
      "LC_ALL=zh_CN.UTF-8"
    ];

    home.packages = with pkgs; [
      nixd
      nixfmt
      markdown-oxide
      yaml-language-server
      basedpyright
      ripgrep
      fd
      sqlite
      emacsPackages.elsa
    ];

    home.file.".emacs.d/init.el".source = ./emacs/init.el;

    home.file.".emacs.d/early-init.el".source = ./emacs/early-init.el;

    home.file.".emacs" = {
      force = true;
      text = ''
        ;;; .emacs --- compatibility loader -*- lexical-binding: t; -*-

        ;; Emacs loads ~/.emacs before ~/.emacs.d/init.el. Keep this file as a
        ;; tiny Home Manager-managed shim so the real config is always loaded.
        (load (expand-file-name "init.el" user-emacs-directory) nil t)

        ;;; .emacs ends here
      '';
    };

    home.sessionVariables = {
      EDITOR = "emacsclient -t -a emacs";
      VISUAL = "emacsclient -t -a emacs";
    };
  };
}
