;;; early-init.el --- startup policy -*- lexical-binding: t; -*-

;; Home Manager/Nix provides Emacs packages through `package-directory-list'.
;; Keep package startup enabled so package autoloads are available, but do not
;; let old packages in ~/.emacs.d/elpa shadow Nix-provided packages.
(setq package-user-dir (expand-file-name "nix-elpa" user-emacs-directory)
      package-quickstart nil)

;;; early-init.el ends here
