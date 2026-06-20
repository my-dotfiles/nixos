;;; init.el --- Small GUI-first Emacs configuration -*- lexical-binding: t; -*-

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

(add-to-list 'default-frame-alist '(font . "Iosevka Nerd Font Mono-13"))
(add-to-list 'default-frame-alist '(alpha-background . 95))
(add-to-list 'default-frame-alist '(tool-bar-lines . 0))
(add-to-list 'default-frame-alist '(vertical-scroll-bars . nil))
(add-to-list 'default-frame-alist '(horizontal-scroll-bars . nil))

(defun yurikon/apply-gui-fonts (&optional frame)
  "Apply GUI fonts to FRAME after it has been created."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (with-selected-frame frame
        (set-frame-font "Iosevka Nerd Font Mono-13" nil t)
        (dolist (charset '(kana han cjk-misc bopomofo))
          (set-fontset-font t charset
                            (font-spec :family "Maple Mono NF CN" :size 16)))))))

(defun yurikon/apply-gui-fonts-later (&optional frame)
  "Apply GUI fonts after FRAME finishes toolkit initialization."
  (run-at-time 0 nil #'yurikon/apply-gui-fonts frame))

(yurikon/apply-gui-fonts)
(add-hook 'after-make-frame-functions #'yurikon/apply-gui-fonts-later)
(add-hook 'server-after-make-frame-hook #'yurikon/apply-gui-fonts-later)

(require 'kkp)
(add-hook 'tty-setup-hook #'global-kkp-mode)
(unless (display-graphic-p)
  (global-kkp-mode 1))

(dolist (theme-library '("gruvbox-dark-hard-theme" "ef-themes"))
  (add-to-list 'custom-theme-load-path
               (file-name-directory (locate-library theme-library))))
(load-theme 'ef-owl t)

(defconst yurikon/terminal-transparent-background-faces
  '(default
    fringe
    header-line
    line-number
    line-number-current-line
    mode-line
    mode-line-active
    mode-line-inactive
    tab-bar
    tab-line
    tab-line-tab
    tab-line-tab-current
    tab-line-tab-inactive
    vertical-border
    window-divider
    window-divider-first-pixel
    window-divider-last-pixel
    corfu-default
    corfu-bar
    corfu-border
    corfu-popupinfo
    org-block
    org-block-begin-line
    org-block-end-line
    org-code
    org-date
    org-document-info
    org-document-info-keyword
    org-document-title
    org-drawer
    org-hide
    org-indent
    org-meta-line
    org-property-value
    org-quote
    org-special-keyword
    org-table
    org-tag
    org-verbatim)
  "Faces whose theme backgrounds should not cover terminal transparency.")

(defun yurikon/terminal-transparent-background (&optional frame)
  "Let terminal FRAME inherit its terminal emulator's transparent background."
  (let ((frame (or frame (selected-frame))))
    (unless (display-graphic-p frame)
      (dolist (face yurikon/terminal-transparent-background-faces)
        (when (facep face)
          (set-face-attribute face frame :background "unspecified-bg"))))))

(yurikon/terminal-transparent-background)
(add-hook 'after-make-frame-functions #'yurikon/terminal-transparent-background)
(add-hook 'server-after-make-frame-hook #'yurikon/terminal-transparent-background)
(advice-add 'load-theme :after
            (lambda (&rest _)
              (yurikon/terminal-transparent-background)))
(dolist (feature '(corfu corfu-popupinfo))
  (with-eval-after-load feature
    (yurikon/terminal-transparent-background)))

(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

;; Use relative line numbers
(setq display-line-numbers-type 'relative)

(global-display-line-numbers-mode 1)
(yurikon/terminal-transparent-background)
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

;; Emacs runs as a daemon, so project-local tooling from direnv must be
;; loaded per buffer instead of inherited from the original service process.
(require 'envrc)
(envrc-global-mode 1)

;; set cursor
(setq-default cursor-type 'box)
(blink-cursor-mode 0)

;; Minibuffer completion.
(require 'vertico)
(require 'marginalia)
(require 'orderless)
(require 'consult)
(vertico-mode 1)
(marginalia-mode 1)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles basic partial-completion))))

(global-set-key (kbd "C-s") #'consult-line)
(global-set-key (kbd "C-x b") #'consult-buffer)
(global-set-key (kbd "C-x C-b") #'ibuffer)
(global-set-key (kbd "M-y") #'consult-yank-pop)
(global-set-key (kbd "M-g g") #'consult-goto-line)
(global-set-key (kbd "C-c f") #'project-find-file)
(global-set-key (kbd "C-c s") #'consult-ripgrep)

(setq xref-show-xrefs-function #'consult-xref
      xref-show-definitions-function #'consult-xref)
(require 'magit)
(global-set-key (kbd "C-c g") #'magit-status)

(require 'prescient)
(require 'vertico-prescient)
(require 'corfu-prescient)

(setq prescient-persist-mode t)
(prescient-persist-mode 1)

;; Only use prescient to order, use orderless to filter
(setq vertico-prescient-enable-filtering nil
      corfu-prescient-enable-filtering nil)
(vertico-prescient-mode 1)
(corfu-prescient-mode 1)

(defun yurikon/wl-copy-region (beg end)
  "Copy the active region to the Wayland clipboard with wl-copy."
  (interactive "r")
  (unless (use-region-p)
    (user-error "No active region"))
  (let ((coding-system-for-write 'utf-8-unix))
    (unless (zerop (call-process-region beg end "wl-copy" nil nil nil
                                        "--type" "text/plain"))
      (user-error "wl-copy failed")))
  (deactivate-mark)
  (message "Copied region to Wayland clipboard"))

(global-set-key (kbd "C-c w") #'yurikon/wl-copy-region)

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

(require 'tempel)
(require 'tempel-collection)

(defun yurikon/tempel-setup-capf ()
  "Let exact Tempel templates participate in completion-at-point."
  (add-hook 'completion-at-point-functions #'tempel-expand nil t))

(defun yurikon/tempel-expand-maybe ()
  "Expand an exact Tempel template at point, returning non-nil on success."
  (condition-case nil
      (progn
        (tempel-expand t)
        t)
    (user-error nil)))

(add-hook 'prog-mode-hook #'yurikon/tempel-setup-capf)
(add-hook 'text-mode-hook #'yurikon/tempel-setup-capf)
(add-hook 'conf-mode-hook #'yurikon/tempel-setup-capf)

(global-set-key (kbd "C-c y c") #'tempel-complete)
(global-set-key (kbd "C-c y i") #'tempel-insert)

(with-eval-after-load 'org
  (require 'org-tempo)

  (defun yurikon/org-cycle-or-tempel-expand ()
    "Expand an exact Tempel template, otherwise fall back to `org-cycle'."
    (interactive)
    (unless (yurikon/tempel-expand-maybe)
      (call-interactively #'org-cycle)))

  (keymap-set org-mode-map "TAB" #'yurikon/org-cycle-or-tempel-expand)
  (keymap-set org-mode-map "<tab>" #'yurikon/org-cycle-or-tempel-expand))

;; Prefer official tree-sitter major modes when Emacs provides them.
(require 'treesit)
(setq treesit-font-lock-level 4)

(defun yurikon/add-major-mode-remap (from to)
  "Remap FROM major mode to TO when TO is available."
  (when (fboundp to)
    (add-to-list 'major-mode-remap-alist (cons from to))))

(defun yurikon/add-auto-mode (regexp mode)
  "Use MODE for files matching REGEXP when MODE is available."
  (when (fboundp mode)
    (add-to-list 'auto-mode-alist (cons regexp mode))))

(dolist (remap '((sh-mode . bash-ts-mode)
                 (c-mode . c-ts-mode)
                 (c++-mode . c++-ts-mode)
                 (c-or-c++-mode . c-or-c++-ts-mode)
                 (csharp-mode . csharp-ts-mode)
                 (css-mode . css-ts-mode)
                 (html-mode . html-ts-mode)
                 (java-mode . java-ts-mode)
                 (js-mode . js-ts-mode)
                 (js-json-mode . json-ts-mode)
                 (python-mode . python-ts-mode)
                 (ruby-mode . ruby-ts-mode)
                 (conf-toml-mode . toml-ts-mode)
                 (yaml-mode . yaml-ts-mode)))
  (yurikon/add-major-mode-remap (car remap) (cdr remap)))

(dolist (entry '(("\\.json\\'" . json-ts-mode)
                 ("\\.ya?ml\\'" . yaml-ts-mode)
                 ("\\.toml\\'" . toml-ts-mode)
                 ("\\.go\\'" . go-ts-mode)
                 ("\\`go\\.mod\\'" . go-mod-ts-mode)
                 ("\\.rs\\'" . rust-ts-mode)
                 ("\\.ts\\'" . typescript-ts-mode)
                 ("\\.tsx\\'" . tsx-ts-mode)
                 ("\\(?:\\`\\|/\\)Dockerfile\\(?:\\..*\\)?\\'" . dockerfile-ts-mode)
                 ("\\(?:\\`\\|/\\)CMakeLists\\.txt\\'" . cmake-ts-mode)
                 ("\\.cmake\\'" . cmake-ts-mode)))
  (yurikon/add-auto-mode (car entry) (cdr entry)))

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
             '((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio")))
(add-to-list 'eglot-server-programs
             '((python-mode python-ts-mode)
               "basedpyright-langserver" "--stdio"))
(add-to-list 'eglot-server-programs
             '((c-mode c-ts-mode c++-mode c++-ts-mode c-or-c++-mode c-or-c++-ts-mode)
               . ("clangd"
                  "--background-index"
                  "--clang-tidy"
                  "--query-driver=/nix/store/**/bin/clang,/nix/store/**/bin/clang++,/nix/store/**/bin/gcc,/nix/store/**/bin/g++")))

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

(require 'ox-publish)

(setq org-publish-project-alist
      '(("org-learning"
         :base-directory "/home/yurikon/Learning/org-learning"
         :publishing-directory "/home/yurikon/Learning/org-learning/public-html"
         :recursive t
         :publishing-function org-html-publish-to-html
         :with-author nil
         :with-creator nil
         :section-numbers t
         :time-stamp-file t
         :exclude "public\\|\\.git\\|\\.obsidian\\|org-roam\\.db")))

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
(add-hook 'yaml-ts-mode-hook #'eglot-ensure)
(add-hook 'nix-mode-hook #'eglot-ensure)
(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(add-hook 'typescript-ts-mode-hook #'eglot-ensure)
(add-hook 'tsx-ts-mode-hook #'eglot-ensure)

(defun yurikon/eglot-ensure-after-envrc ()
  "Refresh direnv for the current buffer before starting Eglot.

This matters for daemon Emacs: project-local tools from a Nix flake are not
inherited from the shell that launches emacsclient.  Refreshing envrc here
ensures clangd is resolved from the project's dev shell before Eglot starts."
  (when (and (bound-and-true-p envrc-mode)
             (fboundp 'envrc--update))
    (envrc--update))
  (eglot-ensure))

(dolist (hook '(c-mode-hook
                c-ts-mode-hook
                c++-mode-hook
                c++-ts-mode-hook
                c-or-c++-mode-hook
                c-or-c++-ts-mode-hook))
  (add-hook hook #'yurikon/eglot-ensure-after-envrc))

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
(global-set-key (kbd "C-,") #'embark-dwim)
(global-set-key (kbd "C-h B") #'embark-bindings)

(setq prefix-help-command #'embark-prefix-help-command)

(add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode)

(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)


(require 'multiple-cursors)
(setq mc/always-run-for-all t)

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

(defun yurikon/open-current-file-externally ()
  "Open the current file with the desktop default application."
  (interactive)
  (let ((file (if (derived-mode-p 'dired-mode)
                  (dired-get-file-for-visit)
                buffer-file-name)))
    (unless file
      (user-error "Current buffer is not visiting a file"))
    (start-process "xdg-open" nil "xdg-open" file)))

(global-set-key (kbd "C-c o") #'yurikon/open-current-file-externally)

;; use mu4e for mail frontend
(require 'mu4e)
(setq mail-user-agent 'mu4e-user-agent)
(setq mu4e-maildir "~/Mail")
(setq mu4e-get-mail-command "mbsync -a")
(setq mu4e-update-interval 600)
(setq mu4e-change-filenames-when-movin t)
(setq mu4e-view-open-program "xdg-open")
(setq mu4e-attachment-dir "~/Downloads")

(require 'mailcap)
(setq mailcap-user-mime-data
      '(("application/pdf" (viewer . "xdg-open %s") (type . "application/pdf"))
        ("application/octet-stream" (viewer . "xdg-open %s") (type . "application/octet-stream"))
        ("application/zip" (viewer . "xdg-open %s") (type . "application/zip"))
        ("application/vnd.*" (viewer . "xdg-open %s") (type . "application/vnd.*"))
        ("image/.*" (viewer . "xdg-open %s") (type . "image/.*"))))
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

;; Keep custom.el separate from the generated init file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
