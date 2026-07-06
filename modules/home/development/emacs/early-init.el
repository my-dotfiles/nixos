;;; early-init.el --- startup policy -*- lexical-binding: t; -*-

;; Keep package startup enabled so Nix-provided package autoloads are available,
;; while preserving a predictable location for any local experiments.
(setq package-user-dir (expand-file-name "managed-elpa" user-emacs-directory)
      package-quickstart nil)

;;; early-init.el ends here
