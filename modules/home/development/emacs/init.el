;;; init.el --- Small terminal-first Emacs configuration -*- lexical-binding: t; -*-

;; This config keeps the normal Emacs editing model. Packages are provided
;; by Nix, so Emacs does not refresh archives or install packages at startup.
;;; Code
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
      doom-themes-enable-italic t)
(load-theme 'doom-gruvbox t)
(when (fboundp 'doom-themes-org-config)
  (doom-themes-org-config))

(menu-bar-mode -1)
(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))

;; Use relative line numbers
(setq display-line-numbers-type 'relative)

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
      eglot-events-buffer-config '(:size 0 :format full))
(add-to-list 'eglot-server-programs
             '((markdown-mode gfm-mode) . ("markdown-oxide")))
(add-to-list 'eglot-server-programs
             '(yaml-mode . ("yaml-language-server" "--stdio")))
(add-to-list 'eglot-server-programs
             '((python-mode python-ts-mode)
               "basedpyright-langserver" "--stdio"))

(require 'nix-mode)
(require 'markdown-mode)
(require 'yaml-mode)
(require 'tuareg)
(require 'ocaml-eglot)

;; Syntax checks.
(require 'flycheck)
(global-flycheck-mode 1)
(with-eval-after-load 'flycheck
  (require 'flycheck-package)
  (flycheck-package-setup)
  (flycheck-add-next-checker 'emacs-lisp 'emacs-lisp-checkdoc)
  (flycheck-add-next-checker 'emacs-lisp-checkdoc 'emacs-lisp-package))

;; Elisp editing support.
(require 'package-lint)
(require 'helpful)

(defun yurikon/emacs-lisp-run-elsa ()
  "Run Elsa on the current Emacs Lisp file."
  (interactive)
  (unless buffer-file-name
    (user-error "This buffer is not visiting a file"))
  (compile (format "elsa %s" (shell-quote-argument buffer-file-name))))

(defun yurikon/emacs-lisp-setup ()
  "Configure local tooling for Emacs Lisp buffers."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (flycheck-mode 1)
  (keymap-local-set "C-c e e" #'yurikon/emacs-lisp-run-elsa))

(add-hook 'emacs-lisp-mode-hook #'yurikon/emacs-lisp-setup)

(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h x") #'helpful-command)

;; Org and org-roam.
(require 'org)
(setq org-directory "/home/yurikon/Learning/org-learning"
      org-default-notes-file (expand-file-name "notes.org" org-directory))
(make-directory org-directory t)

(require 'org-roam)
(setq org-roam-directory (file-truename org-directory)
      org-roam-db-location (expand-file-name "org-roam.db" org-roam-directory)
      org-roam-completion-everywhere t
      org-roam-capture-templates
      '(("d" "default" plain "%?"
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n")
         :unnarrowed t)))
(make-directory org-roam-directory t)
(org-roam-db-autosync-mode 1)

(global-set-key (kbd "C-c n f") #'org-roam-node-find)
(global-set-key (kbd "C-c n i") #'org-roam-node-insert)
(global-set-key (kbd "C-c n c") #'org-roam-capture)
(global-set-key (kbd "C-c n b") #'org-roam-buffer-toggle)
(global-set-key (kbd "C-c n r") #'org-roam-db-sync)

(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
(add-hook 'prog-mode-hook #'hs-minor-mode)

;; Start language servers automatically
(add-hook 'markdown-mode-hook #'eglot-ensure)
(add-hook 'gfm-mode-hook #'eglot-ensure)
(add-hook 'yaml-mode-hook #'eglot-ensure)
(add-hook 'nix-mode-hook #'eglot-ensure)
(add-hook 'python-mode-hook #'eglot-ensure)

;; Python indentation
(setq python-indent-offset 4
      python-indent-guess-indent-offset-verbose nil
      python-shell-interpreter "python")

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


(require 'multiple-cursors)
(setq mc/alawys-run-for-all t)

;; Basic ms
(global-set-key (kbd "C-c m l") #'mc/edit-lines)
(global-set-key (kbd "C-c m m") #'mc/mark-all-like-this)
(global-set-key (kbd "C-c m n") #'mc/mark-next-like-this)
(global-set-key (kbd "C-c m p") #'mc/mark-previous-like-this)
(global-set-key (kbd "C-c m r") #'mc/mark-all-in-region)
(global-set-key (kbd "C-c m d") #'mc/mark-all-symbols-like-this-in-defun)

;; Symbol match
(global-set-key (kbd "C-c m s") #'mc/mark-next-like-this-symbol)
(global-set-key (kbd "C-c m S") #'mc/mark-all-symbols-like-this)

;; Unmark select
(global-set-key (kbd "C-c m u") #'mc/unmark-next-like-this)
(global-set-key (kbd "C-c m U") #'mc/unmark-previous-like-this)
(global-set-key (kbd "C-c m k") #'mc/skip-to-next-like-this)
(global-set-key (kbd "C-c m K") #'mc/skip-to-previous-like-this)

;; Batch edit multiple lines
(global-set-key (kbd "C-c m b") #'mc/edit-beginnings-of-lines)
(global-set-key (kbd "C-c m e") #'mc/edit-ends-of-lines)

;; auto numbers
(global-set-key (kbd "C-c m #") #'mc/insert-numbers)

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
