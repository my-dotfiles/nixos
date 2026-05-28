{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.emacs;
in
{
  options.myHome.development.emacs.enable = lib.mkEnableOption "Emacs configuration";

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
    };

    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      ripgrep
      fd
    ];

    home.file.".emacs.d/init.el".text = ''
      ;; 启用 package 管理器
      (require 'package)
      (setq package-archives
            '(("gnu" . "https://elpa.gnu.org/packages/")
              ("nongnu" . "https://elpa.nongnu.org/nongnu/")
              ("melpa" . "https://melpa.org/packages/")))
      (package-initialize)

      ;; 自动安装插件
      (unless package-archive-contents
        (package-refresh-contents))

      (dolist (pkg '(use-package
                     vertico
                     marginalia
                     orderless
                     consult
                     which-key
                     nix-mode))
        (unless (package-installed-p pkg)
          (ignore-errors
            (package-install pkg))))

      ;; 基本设置
      (require 'use-package)
      (use-package vertico :init (vertico-mode 1))
      (use-package marginalia :init (marginalia-mode 1))
      (use-package orderless
        :custom (completion-styles '(orderless basic)))
      (use-package consult)
      (use-package which-key :config (which-key-mode 1))
      (use-package nix-mode :mode "\\.nix\\'")
      (use-package eglot :ensure nil :hook (nix-mode . eglot-ensure))
    '';

    home.sessionVariables = {
      EDITOR = "emacs";
      VISUAL = "emacs";
    };
  };
}
