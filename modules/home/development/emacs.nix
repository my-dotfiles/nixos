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
          corfu-terminal
          doom-themes
          magit
          marginalia
          markdown-mode
          nix-mode
          orderless
          vertico
          which-key

          avy
          embark
          embark-consult
          rainbow-delimiters
          flycheck

          tuareg
          ocaml-eglot
          
          yaml-mode

          nerd-icons
          nerd-icons-completion
          nerd-icons-dired
        ]
      );
    };

    home.packages = with pkgs; [
      nixd
      nixfmt
      markdown-oxide
      yaml-language-server
      ripgrep
      fd
    ];

    home.file.".emacs.d/init.el".text = ''
      ;;; init.el --- Small terminal-first Emacs configuration -*- lexical-binding: t; -*-

      ;; This config keeps the normal Emacs editing model. Packages are provided
      ;; by Nix, so Emacs does not refresh archives or install packages at startup.
      (setq package-enable-at-startup nil
            package-quickstart nil)

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

      ;; Gruvbox theme from doom-themes, without Doom Emacs or Evil.
      (require 'doom-themes)
      (setq doom-themes-enable-bold t
            doom-themes-enable-italic nil)
      (load-theme 'doom-gruvbox t)
      (when (fboundp 'doom-themes-org-config)
        (doom-themes-org-config))

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
      (require 'which-key)
      (which-key-mode 1)

      (setq-default truncate-lines t)

      ;; set cursor
      (setq-default cursor-type 'box)
      (blink-cursor-mode 1)


      ;; Use relative line numbers
      (setq display-line-numbers-type 'relative)

      ;; Minibuffer completion.
      (require 'vertico)
      (require 'marginalia)
      (require 'orderless)
      (require 'consult)
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
      (require 'magit)
      (global-set-key (kbd "C-c g") #'magit-status)

      ;; In-buffer completion. Works well in terminal and GUI.
      (require 'corfu)
      (require 'cape)
      (global-corfu-mode 1)
      (setq corfu-auto t
            corfu-auto-delay 0.2
            corfu-auto-prefix 2
            corfu-cycle t
            corfu-preselect 'prompt)
      (keymap-set corfu-map "TAB" #'corfu-next)
      (keymap-set corfu-map "<backtab>" #'corfu-previous)
      (keymap-set corfu-map "RET" #'corfu-insert)

      ;; use corfu completion in terminal
      (unless (display-graphic-p)
        (require 'corfu-terminal)
        (corfu-terminal-mode 1))

      (setq tab-always-indent 'complete)

      ;; Extra completion-at-point sources.
      (add-to-list 'completion-at-point-functions #'cape-file)
      (add-to-list 'completion-at-point-functions #'cape-dabbrev)

      ;; corfu-popupinfo
      (require 'corfu-popupinfo)
      (corfu-popupinfo-mode 1)
      (setq corfu-popupinfo-delay '(0.5 . 0.2))

      ;; Built-in project and LSP support.
      (require 'eglot)
      (setq xref-search-program 'ripgrep
            eglot-autoshutdown t
            eglot-events-buffer-size 0)
      (add-to-list 'eglot-server-programs
                   '((markdown-mode gfm-mode) . ("markdown-oxide")))
      (add-to-list 'eglot-server-programs
                   '(yaml-mode . ("yaml-language-server" "--stdio")))

      (require 'nix-mode)
      (require 'markdown-mode)
      (require 'yaml-mode)
      (require 'tuareg)
      (require 'ocaml-eglot)

      (add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
      (add-hook 'prog-mode-hook #'hs-minor-mode)

      ;; Start language servers automatically
      (add-hook 'markdown-mode-hook #'eglot-ensure)
      (add-hook 'gfm-mode-hook #'eglot-ensure)
      (add-hook 'yaml-mode-hook #'eglot-ensure)
      (add-hook 'nix-mode-hook #'eglot-ensure)

      ;; OCaml: Tuareg provides the major mode. OCaml-eglot adds the
      ;; OCaml-specific LSP integration and starts Eglot afterwards.
      (add-hook 'tuareg-mode-hook #'ocaml-eglot-mode)
      (add-hook 'ocaml-eglot-mode-hook #'eglot-ensure)

      ;; Soft wrapping for prose buffers.
      (add-hook 'markdown-mode-hook #'visual-line-mode)
      (add-hook 'gfm-mode-hook #'visual-line-mode)
      (add-hook 'org-mode-hook #'visual-line-mode)

      ;; Fast Jump
      (require 'avy)
      (global-set-key (kbd "C-;") #'avy-goto-char-timer)
      (global-set-key (kbd "M-g w") #'avy-goto-word-1)
      (global-set-key (kbd "M-g l") #'avy-goto-line)

      ;; Context actions for minibuffer
      (require 'embark)
      (require 'embark-consult)
      (global-set-key (kbd "C-.") #'embark-act)
      ;; (global-set-key (kbd "C-,") #'embark-dwim)
      (global-set-key (kbd "C-h B") #'embark-bindings)

      (setq prefix-help-command #'embark-prefix-help-command)

      (add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode)

      (require 'rainbow-delimiters)
      (add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

      ;; nerd icons
      (require 'nerd-icons)
      (require 'nerd-icons-completion)
      (require 'nerd-icons-dired)
      (nerd-icons-completion-mode 1)
      (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)
      (add-hook 'dired-mode-hook #'nerd-icons-dired-mode)

      (global-hl-line-mode 1)


      (add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
      (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
      (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode))

      ;; Keep custom.el separate from the generated init file.
      (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
      (when (file-exists-p custom-file)
        (load custom-file))

      ;;; init.el ends here
    '';

    home.file.".emacs.d/early-init.el".text = ''
      ;;; early-init.el --- startup policy -*- lexical-binding: t; -*-

      ;; Home Manager/Nix provides Emacs packages. Ignore old packages installed
      ;; under ~/.emacs.d/elpa so they cannot shadow Nix-provided Magit,
      ;; Transient, magit-section, Vertico, etc.
      (setq package-enable-at-startup nil
            package-quickstart nil)

      ;;; early-init.el ends here
    '';

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
      EDITOR = "emacs -nw";
      VISUAL = "emacs -nw";
    };
  };
}
