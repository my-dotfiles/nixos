{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.emacs;
  emacsBase =
    if pkgs.stdenv.isDarwin && pkgs ? emacs30 then
      pkgs.emacs30
    else if pkgs.stdenv.isLinux && pkgs ? emacs-pgtk then
      pkgs.emacs-pgtk
    else
      pkgs.emacs;
  emacsPackages = pkgs.emacsPackagesFor emacsBase;
  optionalPkg =
    path:
    let
      value = lib.attrByPath path null pkgs;
    in
    lib.optional (value != null && lib.meta.availableOn pkgs.stdenv.hostPlatform value) value;
  optionalEmacsPkg = pkg: lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkg) pkg;
  treesitGrammarBundle = emacsPackages.treesit-grammars.with-grammars (
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
  );
  emacsPackageList =
    epkgs:
    with epkgs;
    [
      cape
      consult
      corfu
      corfu-terminal
      gruvbox-theme
      ef-themes
      modus-themes
      magit
      marginalia
      markdown-mode
      nix-mode
      org-roam
      orderless
      treesitGrammarBundle
      vertico
      which-key
      htmlize

      avy
      embark
      embark-consult
      envrc
      rainbow-delimiters
      package-lint
      prescient
      corfu-prescient
      vertico-prescient
      elsa
      helpful
      multiple-cursors

      tempel
      tempel-collection

      tuareg
      ocaml-eglot

      yaml-mode

      nerd-icons
      nerd-icons-completion
      nerd-icons-dired
    ]
    ++ lib.optionals cfg.enableKkp (optionalEmacsPkg kkp)
    ++ lib.optionals cfg.enablePdfTools (optionalEmacsPkg pdf-tools)
    ++ lib.optionals cfg.enableMail (optionalEmacsPkg mu4e ++ optionalEmacsPkg org-mime);
  emacsPackageEnv = pkgs.buildEnv {
    name = "emacs-elpa-packages";
    paths = emacsPackageList emacsPackages;
    pathsToLink = [ "/share/emacs/site-lisp" ];
    ignoreCollisions = true;
  };
  emacsWithPackages = emacsPackages.emacsWithPackages emacsPackageList;
  homebrewPrefix = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local";
  emacsPlusPrefix = "${homebrewPrefix}/opt/emacs-plus@30";
  emacsProgram =
    if pkgs.stdenv.isDarwin then "${emacsPlusPrefix}/bin/emacs" else lib.getExe emacsWithPackages;
  emacsclientProgram =
    if pkgs.stdenv.isDarwin then
      "${emacsPlusPrefix}/bin/emacsclient"
    else
      lib.getExe' emacsWithPackages "emacsclient";
  homebrewGccBin = "${homebrewPrefix}/opt/gcc/bin";
  homebrewGccLib = "${homebrewPrefix}/opt/gcc/lib/gcc/current";
  homebrewLibgccjitInclude = "${homebrewPrefix}/opt/libgccjit/include";
  homebrewLibgccjitLib = "${homebrewPrefix}/opt/libgccjit/lib/gcc/current";
  nativeCompLibraryPath = lib.concatStringsSep ":" [
    homebrewLibgccjitLib
    homebrewGccLib
  ];
  copyCommand = if pkgs.stdenv.isDarwin then "pbcopy" else lib.getExe' pkgs.wl-clipboard "wl-copy";
  copyArgs = if pkgs.stdenv.isDarwin then "" else "\"--type\" \"text/plain\"";
  openCommand = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
  mailConfig =
    if cfg.enableMail then
      ''
        ;; use mu4e for mail frontend
        (require 'mu4e)
        (setq mail-user-agent 'mu4e-user-agent)
        (setq mu4e-maildir "~/Mail")
        (setq mu4e-get-mail-command "mbsync -a")
        (setq mu4e-update-interval 600)
        (setq mu4e-change-filenames-when-movin t)
        (setq mu4e-view-open-program "${openCommand}")
        (setq mu4e-attachment-dir "~/Downloads")

        (require 'mailcap)
        (setq mailcap-user-mime-data
              '(("application/pdf" (viewer . "${openCommand} %s") (type . "application/pdf"))
                ("application/octet-stream" (viewer . "${openCommand} %s") (type . "application/octet-stream"))
                ("application/zip" (viewer . "${openCommand} %s") (type . "application/zip"))
                ("application/vnd.*" (viewer . "${openCommand} %s") (type . "application/vnd.*"))
                ("image/.*" (viewer . "${openCommand} %s") (type . "image/.*"))))
        (mailcap-parse-mailcaps)
        (dolist (mime-type '("application/pdf"
                             "application/octet-stream"
                             "application/zip"
                             "application/vnd.*"))
          (setq mm-inlined-types (delete mime-type mm-inlined-types)))

        (setq message-send-mail-function 'message-send-mail-with-sendmail)
        (setq sendmail-program "msmtp")
        (setq message-sendmail-extra-arguments '("--read-envelope-from"))
        (setq message-sendmail-f-is-evil t)
        (setq message-kill-buffer-on-exit t)

        (setq mu4e-contexts
              (list
              (make-mu4e-context
               :name "gmail"
               :match-func (lambda (msg)
                             (when msg
                               (string-prefix-p "/gmail" (mu4e-message-field msg :maildir))))
               :vars '((user-mail-address . "h6606797@gmail.com")
                       (user-full-name . "Yurikon")))
              (make-mu4e-context
               :name "qq"
               :match-func (lambda (msg)
                             (when msg
                               (string-prefix-p "/qq" (mu4e-message-field msg :maildir))))
               :vars '((user-mail-address . "3166701497@qq.com")
                       (user-full-name . "郑彦文")))
              (make-mu4e-context
               :name "163"
               :match-func (lambda (msg)
                             (when msg
                               (string-prefix-p "/netease163" (mu4e-message-field msg :maildir))))
               :vars '((user-mail-address . "yuriisbest@163.com")
                       (user-full-name . "Yurikon")))))
      ''
    else
      "";
  pdfToolsConfig =
    if cfg.enablePdfTools then
      ''
        ;; PDF reading inside Emacs.
        (require 'pdf-tools)
        (add-to-list 'pdf-tools-enabled-modes 'pdf-view-auto-slice-minor-mode)
        (pdf-tools-install t nil t)
        (setq-default pdf-view-display-size 'fit-page)
        (add-hook 'pdf-view-mode-hook
                  (lambda ()
                    (display-line-numbers-mode 0)
                    (auto-revert-mode 1)))
      ''
    else
      "";
  kkpConfig =
    if cfg.enableKkp then
      ''
        (require 'kkp)
        (add-hook 'tty-setup-hook #'global-kkp-mode)
        (unless (display-graphic-p)
          (global-kkp-mode 1))
      ''
    else
      "";
  packageBootstrap = ''
    ;; Editor packages are built by Nix. On macOS, Homebrew emacs-plus supplies
    ;; the application and command-line binaries.
    (require 'package)
    (setq package-enable-at-startup nil
          package-archives nil
          package-directory-list
          '("${emacsPackageEnv}/share/emacs/site-lisp/elpa")
          treesit-extra-load-path
          '("${treesitGrammarBundle}/lib"))
    (package-initialize)
  '';
  initEl =
    builtins.replaceStrings
      [
        "@copy-command@"
        "@copy-args@"
        "@open-command@"
        "@mail-config@"
        "@pdf-tools-config@"
        "@kkp-config@"
        "@package-bootstrap@"
      ]
      [
        copyCommand
        copyArgs
        openCommand
        mailConfig
        pdfToolsConfig
        kkpConfig
        packageBootstrap
      ]
      (builtins.readFile ./emacs/init.el);
in
{
  options.myHome.development.emacs = {
    enable = lib.mkEnableOption "Emacs configuration";
    enableMail = lib.mkEnableOption "mu4e mail integration";
    enablePdfTools = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isLinux;
      description = "Enable pdf-tools package and Emacs setup.";
    };
    enableKkp = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable kkp terminal keyboard protocol support.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.emacs = lib.mkIf (!pkgs.stdenv.isDarwin) {
          enable = true;
          package = emacsWithPackages;
        };

        home.file.".local/bin/emacs" = lib.mkIf pkgs.stdenv.isDarwin {
          executable = true;
          text = ''
            #!/usr/bin/env bash

            export PATH="${homebrewGccBin}:$PATH"
            export CPATH="${homebrewLibgccjitInclude}''${CPATH:+:$CPATH}"
            export LIBRARY_PATH="${nativeCompLibraryPath}''${LIBRARY_PATH:+:$LIBRARY_PATH}"

            exec ${emacsProgram} --init-directory "$HOME/.emacs.d" "$@"
          '';
        };

        home.file.".local/bin/emacsclient" = lib.mkIf pkgs.stdenv.isDarwin {
          executable = true;
          text = ''
            #!/usr/bin/env bash

            exec ${emacsclientProgram} "$@"
          '';
        };

        home.packages =
          lib.concatMap optionalPkg [
            [ "nixd" ]
            [ "nixfmt" ]
            [ "clang-tools" ]
            [ "markdown-oxide" ]
            [ "yaml-language-server" ]
            [ "basedpyright" ]
            [ "typescript-language-server" ]
            [ "ripgrep" ]
            [ "fd" ]
            [ "sqlite" ]
          ]
          ++ lib.optionals pkgs.stdenv.isLinux (optionalPkg [ "wl-clipboard" ])
          ++ lib.optionals (!pkgs.stdenv.isDarwin) (optionalEmacsPkg emacsPackages.elsa);

        home.file.".emacs.d/init.el".text = initEl;

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
      }

      (lib.mkIf pkgs.stdenv.isLinux {
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
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.emacs = {
          enable = true;
          config = {
            ProgramArguments = [
              "${config.home.homeDirectory}/.local/bin/emacs"
              "--fg-daemon"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            WorkingDirectory = config.home.homeDirectory;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/emacs-daemon.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/emacs-daemon.log";
            EnvironmentVariables = {
              HOME = config.home.homeDirectory;
              LANG = "en_US.UTF-8";
              LC_CTYPE = "en_US.UTF-8";
              CPATH = homebrewLibgccjitInclude;
              LIBRARY_PATH = nativeCompLibraryPath;
              PATH = lib.concatStringsSep ":" [
                "/etc/profiles/per-user/${config.home.username}/bin"
                "${config.home.homeDirectory}/.nix-profile/bin"
                "${config.home.homeDirectory}/.local/state/nix/profile/bin"
                "${config.home.homeDirectory}/.local/bin"
                homebrewGccBin
                "${homebrewPrefix}/bin"
                "/nix/var/nix/profiles/default/bin"
                "/usr/local/bin"
                "/usr/bin"
                "/bin"
                "/usr/sbin"
                "/sbin"
              ];
            };
          };
        };
      })
    ]
  );
}
