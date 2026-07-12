;;; init.el --- 以图形界面为主的精简 Emacs 配置 -*- lexical-binding: t; -*-

;; 本配置保留 Emacs 的常规编辑方式。软件包由 Nix 提供，因此 Emacs
;; 启动时不会刷新软件包归档或自行安装软件包。
;;; Code
(setq package-quickstart nil)

(setq inhibit-startup-screen t
      ring-bell-function 'ignore
      use-short-answers t
      make-backup-files nil
      auto-save-default t
      create-lockfiles nil
      column-number-mode t
      sentence-end-double-space nil
      read-process-output-max (* 1024 1024))

;; 这些变量进入主模式后会变成缓冲区局部变量，因此应设置默认值，
;; 而不是只修改启动缓冲区中的值。
(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 100
              truncate-lines t)

;; 默认 GC 阈值较小，补全和语言服务器分配候选项时容易产生可感知的停顿。
;; 同时保留字体缓存，避免多语言缓冲区因重建字体缓存而阻塞重绘。
(setq gc-cons-threshold (* 32 1024 1024)
      gc-cons-percentage 0.1
      inhibit-compacting-font-caches t
      process-adaptive-read-buffering nil
      ;; 避免 PGTK 在每次 GUI 状态变化后最多等待 100 毫秒。
      pgtk-wait-for-event-timeout 0.01)

;; 输入尚未结束时优先响应按键，把字体锁定和非关键重绘推迟到短暂空闲期。
;; 禁用括号配对算法只影响少见的双向文本括号排版，不影响中文和常规代码。
(setq redisplay-skip-fontification-on-input t
      jit-lock-defer-time 0.05
      jit-lock-stealth-time 1.0
      jit-lock-stealth-nice 0.1
      idle-update-delay 0.2
      auto-window-vscroll nil
      bidi-inhibit-bpa t)

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

(defconst yurikon/default-font-family "Iosevka Nerd Font Mono"
  "Default Latin monospace font family.")

(defconst yurikon/default-font-size 13
  "Default GUI font size in points.")

(defconst yurikon/cjk-font-family "Maple Mono NF CN"
  "CJK fallback font family.")

(defun yurikon/default-font-name ()
  "Return the default GUI font name."
  (format "%s-%d" yurikon/default-font-family yurikon/default-font-size))

(setq face-font-rescale-alist
      `((,yurikon/cjk-font-family . 1.0)))

(add-to-list 'default-frame-alist `(font . ,(yurikon/default-font-name)))
(add-to-list 'default-frame-alist '(tool-bar-lines . 0))
(add-to-list 'default-frame-alist '(vertical-scroll-bars . nil))
(add-to-list 'default-frame-alist '(horizontal-scroll-bars . nil))

(defun yurikon/apply-gui-fonts (&optional frame)
  "Apply GUI fonts to FRAME after it has been created."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (with-selected-frame frame
        (set-frame-font (yurikon/default-font-name) nil t)
        (dolist (charset '(kana han cjk-misc bopomofo))
          (set-fontset-font t charset
                            (font-spec :family yurikon/cjk-font-family)))))))

(defun yurikon/apply-gui-fonts-later (&optional frame)
  "Apply GUI fonts after FRAME finishes toolkit initialization."
  (run-at-time 0 nil #'yurikon/apply-gui-fonts frame))

(yurikon/apply-gui-fonts)
(add-hook 'after-make-frame-functions #'yurikon/apply-gui-fonts-later)
(add-hook 'server-after-make-frame-hook #'yurikon/apply-gui-fonts-later)

(dolist (theme-library '("gruvbox-dark-hard-theme" "ef-themes" "modus-themes"))
  (add-to-list 'custom-theme-load-path
               (file-name-directory (locate-library theme-library))))

(defconst yurikon/light-theme 'modus-operandi
  "Theme used by `switch-theme' for daytime editing.")

(defconst yurikon/dark-theme 'modus-vivendi
  "Theme used by `switch-theme' for nighttime editing.")

(defun yurikon/load-theme (theme)
  "Disable active themes, then load THEME."
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))

(defun switch-theme ()
  "Switch between `yurikon/light-theme' and `yurikon/dark-theme'."
  (interactive)
  (let ((theme (if (memq yurikon/dark-theme custom-enabled-themes)
                   yurikon/light-theme
                 yurikon/dark-theme)))
    (yurikon/load-theme theme)
    (message "Switched to %s" theme)))

(yurikon/load-theme yurikon/light-theme)

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

(require 'pixel-scroll)
(setq scroll-conservatively 101
      scroll-margin 3
      scroll-step 1
      scroll-preserve-screen-position 1
      fast-but-imprecise-scrolling t
      mouse-wheel-scroll-amount '(1 ((shift) . hscroll))
      mouse-wheel-progressive-speed nil
      pixel-scroll-precision-use-momentum t
      pixel-scroll-precision-interpolate-page t
      pixel-scroll-precision-momentum-min-velocity 20.0
      pixel-scroll-precision-momentum-seconds 0.6)

(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;; 相对行号会在光标纵向移动后更新所有可见行号；绝对行号能减少窗口重绘。
(setq display-line-numbers-type t
      display-line-numbers-width-start t)
(when (boundp 'display-line-numbers-exempt-modes)
  (add-to-list 'display-line-numbers-exempt-modes 'pdf-view-mode))

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
;; 按 RET 时重新缩进刚结束的当前行，并按照主模式规则缩进新行。
;; C-j 仍然只插入换行，可用于需要保留原始缩进的场景。
(setq electric-pair-open-newline-between-pairs t)
(electric-indent-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)
(delete-selection-mode 1)
(repeat-mode 1)
(winner-mode 1)
(when (fboundp 'global-so-long-mode)
  (global-so-long-mode 1))
(require 'which-key)
(which-key-mode 1)

;; 设置光标。
(setq-default cursor-type 'box)
(blink-cursor-mode 0)

;; minibuffer 补全。
(require 'vertico)
(require 'marginalia)
(require 'orderless)
(require 'consult)
(setq enable-recursive-minibuffers t)
(minibuffer-depth-indicate-mode 1)
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

;; 根据窗口上显示的按键快速选择可见窗口。
(require 'ace-window)
(global-set-key (kbd "M-o") #'ace-window)

;; 让 grep-mode 使用 ripgrep 输出，同时保留 Emacs 内置的 next-error 工作流。
(setq grep-command "rg --vimgrep --smart-case --hidden --glob '!.git' "
      grep-use-null-device nil)

(require 'magit)
(global-set-key (kbd "C-c g") #'magit-status)

(defun yurikon/wl-copy-region (beg end)
  "Copy the active region to the Wayland clipboard with wl-copy."
  (interactive "r")
  (unless (use-region-p)
    (user-error "No active region"))
  (let ((coding-system-for-write 'utf-8-unix))
    (unless (zerop (call-process-region beg end "@wl-copy@" nil nil nil
                                        "--type" "text/plain"))
      (user-error "wl-copy failed")))
  (deactivate-mark)
  (message "Copied region to Wayland clipboard"))

(global-set-key (kbd "C-c w") #'yurikon/wl-copy-region)

;; 缓冲区内补全，同时适用于终端和图形界面。
(require 'corfu)
(setq global-corfu-modes '((not comint-mode gud-mode) t)
      global-corfu-minibuffer nil)
(global-corfu-mode 1)
(setq corfu-auto t
      corfu-auto-delay 0.2
      corfu-auto-prefix 2
      corfu-cycle t
      corfu-preselect 'prompt)

(defun yurikon/corfu-defaults ()
  "为自动补全使用稳定且开销较低的前缀匹配。"
  (setq-local completion-styles '(basic)
              completion-category-defaults nil
              completion-category-overrides nil))

(add-hook 'corfu-mode-hook #'yurikon/corfu-defaults)
;; 自动弹窗出现时，TAB 接受补全，RET 始终交还主模式用于换行。
(keymap-unset corfu-map "RET")

(defun yurikon/gud-corfu-setup ()
  "Show GUD completions with Corfu only when completion is requested."
  (setq-local corfu-auto nil)
  (corfu-mode 1)
  (keymap-local-set "TAB" #'completion-at-point)
  (keymap-local-set "C-i" #'completion-at-point))

(add-hook 'gud-mode-hook #'yurikon/gud-corfu-setup)

;; 保持 TAB 行为确定：Corfu 弹窗之外只执行缩进。仍可通过 M-TAB 显式补全，
;; Corfu 也会自动弹出。
(setq tab-always-indent t
      electric-indent-actions nil)

(require 'tempel)
(require 'tempel-collection)

;; Tempel 活跃时，使用更顺手的方括号键在占位符之间移动。
(keymap-unset tempel-map "M-{")
(keymap-unset tempel-map "M-}")
(keymap-set tempel-map "M-[" #'tempel-previous)
(keymap-set tempel-map "M-]" #'tempel-next)

(defun yurikon/tempel-setup-capf ()
  "按照 Tempel 推荐方式，在当前缓冲区启用精确匹配的模板展开。"
  (setq-local completion-at-point-functions
              (cons #'tempel-expand completion-at-point-functions)))

(add-hook 'conf-mode-hook #'yurikon/tempel-setup-capf)
(add-hook 'prog-mode-hook #'yurikon/tempel-setup-capf)
(add-hook 'text-mode-hook #'yurikon/tempel-setup-capf)
(global-set-key (kbd "M-+") #'tempel-complete)
(global-set-key (kbd "M-*") #'tempel-insert)

;; 将语言服务器返回的代码片段交给 Tempel，补全函数时展开括号和参数占位符。
(require 'eglot-tempel)
(eglot-tempel-mode 1)

;; 优先使用 Emacs 提供的官方 tree-sitter 主模式。第 4 级会增加开销，
;; 但额外的高亮细节在日常编辑中并不明显。
(require 'treesit)
(setq treesit-font-lock-level 3
      c-ts-mode-enable-doxygen t
      c-ts-indent-offset 2
      c-basic-offset 2)

(defun yurikon/c-ts-indent-style ()
  "在 GNU 风格基础上修正类内函数定义的缩进。"
  (let* ((language (if (derived-mode-p 'c++-ts-mode) 'cpp 'c))
         (rules (alist-get language
                           (c-ts-mode--simple-indent-rules language 'gnu))))
    `((,language
       . (((match "function_definition" "field_declaration_list")
           parent-bol c-ts-mode-indent-offset)
          ,@rules)))))

(setq c-ts-mode-indent-style #'yurikon/c-ts-indent-style)

(defun yurikon/c++-newline-and-indent ()
  "换行并缩进；在相邻花括号之间将光标留在缩进后的空行。"
  (interactive)
  (if (and (eq (char-before) ?{)
           (eq (char-after) ?}))
      (progn
        (newline 2)
        (forward-line -1)
        (indent-according-to-mode)
        (save-excursion
          (forward-line 1)
          (indent-according-to-mode)))
    (newline-and-indent)))

(defun yurikon/c++-editing-setup ()
  "为 C++ tree-sitter 缓冲区设置可靠的 RET 行为。"
  (keymap-local-set "RET" #'yurikon/c++-newline-and-indent))

(add-hook 'c++-ts-mode-hook #'yurikon/c++-editing-setup)

;; 允许项目通过自己的 .editorconfig 覆盖缩进和空白字符默认设置；
;; 现代 Emacs 已内置这项集成。
(require 'editorconfig)
(editorconfig-mode 1)

(customize-set-variable
 'treesit-enabled-modes
 '(bash-ts-mode
   c-ts-mode
   c++-ts-mode
   c-or-c++-ts-mode
   cmake-ts-mode
   csharp-ts-mode
   css-ts-mode
   dockerfile-ts-mode
   go-ts-mode
   go-mod-ts-mode
   html-ts-mode
   java-ts-mode
   js-ts-mode
   json-ts-mode
   python-ts-mode
   ruby-ts-mode
   rust-ts-mode
   toml-ts-mode
   tsx-ts-mode
   typescript-ts-mode
   yaml-ts-mode))

;; Emacs 31 的标准重映射表不包含这些旧模式名，但内置文件关联仍会使用它们。
(add-to-list 'major-mode-remap-alist '(html-mode . html-ts-mode))
(add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode))

(defun yurikon/add-auto-mode (regexp mode)
  "Use MODE for files matching REGEXP when MODE is available."
  (when (fboundp mode)
    (add-to-list 'auto-mode-alist (cons regexp mode))))

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

;; Corfu 候选文档弹窗。
(require 'corfu-popupinfo)
(corfu-popupinfo-mode 1)
;; 保留通过 M-t 查看文档的能力，但候选项变化时不再自动创建额外的 child frame。
(setq corfu-popupinfo-delay nil)

;; 内置项目管理与 LSP 支持。
(require 'xref)
(require 'eglot)
(require 'eldoc)
(setq xref-search-program 'ripgrep
      xref-show-definitions-function #'xref-show-definitions-completing-read
      eglot-autoshutdown t
      eglot-events-buffer-config '(:size 0 :format full)
      eldoc-idle-delay 0.3
      eldoc-echo-area-use-multiline-p 1)

;; Eglot 通过内置 ElDoc 在回显区显示光标处符号的签名、参数和类型。
(add-hook 'eglot-managed-mode-hook #'eldoc-mode)
(add-to-list 'eglot-server-programs
             '((markdown-mode gfm-mode) . ("markdown-oxide")))
(add-to-list 'eglot-server-programs
             '((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio")))
(add-to-list 'eglot-server-programs
             '(nix-mode . ("nixd")))
(add-to-list 'eglot-server-programs
             '((python-mode python-ts-mode)
               "basedpyright-langserver" "--stdio"))
(add-to-list 'eglot-server-programs
             '(cmake-ts-mode . ("cmake-language-server")))
(add-to-list 'eglot-server-programs
             '((c-mode c-ts-mode c++-mode c++-ts-mode c-or-c++-mode c-or-c++-ts-mode)
               . ("clangd"
                  "--background-index"
                  "--clang-tidy"
                  "--query-driver=/nix/store/**/bin/clang,/nix/store/**/bin/clang++,/nix/store/**/bin/gcc,/nix/store/**/bin/g++")))

(with-eval-after-load 'eglot
  (keymap-set eglot-mode-map "C-c l a" #'eglot-code-actions)
  (keymap-set eglot-mode-map "C-c l r" #'eglot-rename)
  (keymap-set eglot-mode-map "C-c l f" #'eglot-format-buffer)
  (keymap-set eglot-mode-map "C-c l o" #'eglot-code-action-organize-imports))

(require 'nix-mode)
(require 'markdown-mode)
(require 'yaml-mode)
(require 'tuareg)
(require 'ocaml-eglot)

;; 语法检查。
(setq flymake-no-changes-timeout 1.0)

;; Emacs Lisp 编辑支持。
(require 'helpful)

(defun yurikon/emacs-lisp-setup ()
  "Configure local tooling for Emacs Lisp buffers."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (flymake-mode 1))

(add-hook 'emacs-lisp-mode-hook #'yurikon/emacs-lisp-setup)

(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h x") #'helpful-command)

;; Org 与 org-roam。
(require 'org)
(setq org-directory "/home/yurikon/Learning/org-learning"
      org-default-notes-file (expand-file-name "notes.org" org-directory))
(make-directory org-directory t)
(defconst yurikon/org-quick-notes-directory
  (expand-file-name "00-quick/" org-directory)
  "Directory for short-lived Org notes before they are moved elsewhere.")
(make-directory yurikon/org-quick-notes-directory t)

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
         :exclude "public\\|00-quick\\|\\.git\\|\\.obsidian\\|org-roam\\.db")))

(require 'org-roam)
(setq org-roam-directory (file-truename org-directory)
      org-roam-db-location (expand-file-name "org-roam.db" org-roam-directory)
      org-roam-completion-everywhere t
      org-roam-capture-templates
      '(("d" "default" plain "%?"
         :target (file+head "00-quick/%<%Y%m%d%H%M%S>-${slug}.org"
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

;; 自动启动语言服务器。
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
  "在项目环境准备完成后为 C、C++ 和 CMake 启动 Eglot。"
  (when (derived-mode-p 'c-mode 'c-ts-mode
                        'c++-mode 'c++-ts-mode
                        'c-or-c++-mode 'c-or-c++-ts-mode
                        'cmake-ts-mode)
    (eglot-ensure)))

;; Emacs 以守护进程运行，项目工具来自各自的 Nix dev shell。
;; envrc-mode-hook 是公开接口，并且在缓冲区环境应用完成后运行。
(require 'envrc)
(add-hook 'envrc-mode-hook #'yurikon/eglot-ensure-after-envrc)
(envrc-global-mode 1)

;; Python 缩进。
(setq python-indent-offset 4
      python-indent-guess-indent-offset-verbose nil
      python-shell-interpreter "python")

;; OCaml：Tuareg 提供主模式，OCaml-eglot 添加 OCaml 专用的 LSP 集成，
;; 随后启动 Eglot。
(add-hook 'tuareg-mode-hook #'ocaml-eglot-mode)
(add-hook 'ocaml-eglot-mode-hook #'eglot-ensure)

;; 为自然语言文本缓冲区启用软换行。
(add-hook 'markdown-mode-hook #'visual-line-mode)
(add-hook 'gfm-mode-hook #'visual-line-mode)
(add-hook 'org-mode-hook #'visual-line-mode)

;; 在 Emacs 内阅读 PDF。
(require 'pdf-tools)
(require 'pdf-occur)
(add-to-list 'pdf-tools-enabled-modes 'pdf-view-auto-slice-minor-mode)
(pdf-tools-install t nil t)
(setq-default pdf-view-display-size 'fit-page)
(add-hook 'pdf-view-mode-hook
          (lambda ()
            (display-line-numbers-mode 0)
            (auto-revert-mode 1)))

;; 快速跳转。
(require 'avy)
(global-set-key (kbd "C-;") #'avy-goto-char-timer)
(global-set-key (kbd "M-g w") #'avy-goto-word-1)
(global-set-key (kbd "M-g l") #'avy-goto-line)

;; minibuffer 上下文操作。
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

;; multiple-cursors 基础操作。
(global-set-key (kbd "C-c m l") #'mc/edit-lines)
(global-set-key (kbd "C-c m m") #'mc/mark-all-like-this)
(global-set-key (kbd "C-c m n") #'mc/mark-next-like-this)
(global-set-key (kbd "C-c m p") #'mc/mark-previous-like-this)
(global-set-key (kbd "C-c m r") #'mc/mark-all-in-region)
(global-set-key (kbd "C-c m d") #'mc/mark-all-symbols-like-this-in-defun)

;; 符号匹配。
(global-set-key (kbd "C-c m s") #'mc/mark-next-like-this-symbol)
(global-set-key (kbd "C-c m S") #'mc/mark-all-symbols-like-this)

;; 取消或跳过选择。
(global-set-key (kbd "C-c m u") #'mc/unmark-next-like-this)
(global-set-key (kbd "C-c m U") #'mc/unmark-previous-like-this)
(global-set-key (kbd "C-c m k") #'mc/skip-to-next-like-this)
(global-set-key (kbd "C-c m K") #'mc/skip-to-previous-like-this)

;; 批量编辑多行。
(global-set-key (kbd "C-c m b") #'mc/edit-beginnings-of-lines)
(global-set-key (kbd "C-c m e") #'mc/edit-ends-of-lines)

;; 自动插入序号。
(global-set-key (kbd "C-c m #") #'mc/insert-numbers)

;; Nerd Icons 图标。
(require 'nerd-icons)
(require 'nerd-icons-completion)
(require 'nerd-icons-dired)
(nerd-icons-completion-mode 1)
(add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)
(add-hook 'dired-mode-hook #'nerd-icons-dired-mode)

(global-hl-line-mode 1)

(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
(dolist (regexp '("\\.md\\'"
                  "\\.markdown\\'"
                  "\\.mdown\\'"
                  "\\.mkd\\'"
                  "\\.mkdn\\'"))
  (add-to-list 'auto-mode-alist (cons regexp 'markdown-mode)))
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

;; 使用 mu4e 作为邮件前端。
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

;; 将 custom.el 与生成的 init 文件分开保存。
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
