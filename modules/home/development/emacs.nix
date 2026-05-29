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
      package = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages (
        epkgs: with epkgs; [
          cape
          consult
          corfu
          magit
          marginalia
          markdown-mode
          nix-mode
          orderless
          vertico
          which-key
        ]
      );
    };

    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      ripgrep
      fd
    ];

    home.file.".emacs.d/init.el".text = ''
      ;;; init.el --- Small terminal-first Emacs configuration -*- lexical-binding: t; -*-

      ;; This config keeps the normal Emacs editing model. Packages are provided
      ;; by Nix, so Emacs does not refresh archives or install packages at startup.

      (setq inhibit-startup-screen t
            ring-bell-function 'ignore
            use-short-answers t
            make-backup-files nil
            auto-save-default t
            create-lockfiles nil
            column-number-mode t
            sentence-end-double-space nil
            indent-tabs-mode nil
            tab-width 2
            fill-column 100
            read-process-output-max (* 1024 1024))

      (set-language-environment "UTF-8")
      (prefer-coding-system 'utf-8)

      (menu-bar-mode -1)
      (when (display-graphic-p)
        (tool-bar-mode -1)
        (scroll-bar-mode -1))

      (global-display-line-numbers-mode 1)
      (dolist (hook '(term-mode-hook
                      shell-mode-hook
                      eshell-mode-hook
                      vterm-mode-hook
                      comint-mode-hook))
        (add-hook hook (lambda () (display-line-numbers-mode 0))))

      (show-paren-mode 1)
      (electric-pair-mode 1)
      (save-place-mode 1)
      (savehist-mode 1)
      (recentf-mode 1)
      (global-auto-revert-mode 1)
      (delete-selection-mode 1)
      (which-key-mode 1)

      (setq-default truncate-lines t)

      ;; Minibuffer completion.
      (vertico-mode 1)
      (marginalia-mode 1)
      (setq completion-styles '(orderless basic)
            completion-category-defaults nil
            completion-category-overrides '((file (styles partial-completion))))

      (global-set-key (kbd "C-s") #'consult-line)
      (global-set-key (kbd "C-x b") #'consult-buffer)
      (global-set-key (kbd "M-y") #'consult-yank-pop)
      (global-set-key (kbd "M-g g") #'consult-goto-line)
      (global-set-key (kbd "C-c f") #'project-find-file)
      (global-set-key (kbd "C-c s") #'consult-ripgrep)
      (global-set-key (kbd "C-c g") #'magit-status)

      ;; In-buffer completion. Works well in terminal and GUI.
      (global-corfu-mode 1)
      (setq corfu-auto t
            corfu-auto-delay 0.2
            corfu-auto-prefix 2
            corfu-cycle t
            corfu-preselect 'prompt)
      (keymap-set corfu-map "TAB" #'corfu-next)
      (keymap-set corfu-map "<backtab>" #'corfu-previous)
      (keymap-set corfu-map "RET" #'corfu-insert)

      ;; Extra completion-at-point sources.
      (add-to-list 'completion-at-point-functions #'cape-file)
      (add-to-list 'completion-at-point-functions #'cape-dabbrev)

      ;; Built-in project and LSP support.
      (setq xref-search-program 'ripgrep
            eglot-autoshutdown t
            eglot-events-buffer-size 0)

      (add-hook 'nix-mode-hook #'eglot-ensure)
      (add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
      (add-hook 'prog-mode-hook #'hs-minor-mode)

      (add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
      (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

      ;; Keep custom.el separate from the generated init file.
      (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
      (when (file-exists-p custom-file)
        (load custom-file))

      ;;; init.el ends here
    '';

    home.sessionVariables = {
      EDITOR = "emacs";
      VISUAL = "emacs";
    };
  };
}
