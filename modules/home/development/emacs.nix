{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.emacs;
  emacsPackages = pkgs.emacsPackagesFor pkgs.emacs31-pgtk;
  treeSitterDoxygen = pkgs.vimPlugins.nvim-treesitter.builtGrammars.doxygen;
  wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
in
{
  options.myHome.development.emacs.enable = lib.mkEnableOption "Emacs configuration";

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = emacsPackages.emacsWithPackages (
        epkgs: with epkgs; [
          consult
          corfu
          gruvbox-theme
          ef-themes
          modus-themes
          magit
          marginalia
          markdown-mode
          nix-mode
          haskell-mode
          haskell-ts-mode
          org-roam
          orderless
          pdf-tools
          (treesit-grammars.with-grammars (
            grammars: with grammars; [
              tree-sitter-bash
              tree-sitter-c
              tree-sitter-c-sharp
              tree-sitter-cmake
              tree-sitter-cpp
              tree-sitter-css
              tree-sitter-dockerfile
              treeSitterDoxygen
              tree-sitter-go
              tree-sitter-gomod
              tree-sitter-html
              tree-sitter-haskell
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

          ace-window
          avy
          embark
          embark-consult
          envrc
          rainbow-delimiters
          helpful
          multiple-cursors

          tempel
          tempel-collection
          eglot-tempel

          tuareg
          ocaml-eglot

          yaml-mode

          nerd-icons
          nerd-icons-completion
          nerd-icons-corfu
          nerd-icons-dired

          mu4e
          org-mime
        ]
      );
    };

    services.emacs = {
      enable = true;
      client.enable = true;
      socketActivation.enable = true;
      startWithUserSession = false;
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
      wl-clipboard
    ];

    home.file.".emacs.d/init.el".text = builtins.replaceStrings [ "@wl-copy@" ] [ wlCopy ] (
      builtins.readFile ./emacs/init.el
    );

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
