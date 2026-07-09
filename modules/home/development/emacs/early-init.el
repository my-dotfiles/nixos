;;; early-init.el --- startup policy -*- lexical-binding: t; -*-

;; Nix provides Emacs packages through the wrapped Emacs environment. Keep any
;; local experiments isolated from the managed package set.
(setq package-user-dir (expand-file-name "local-elpa" user-emacs-directory)
      package-quickstart nil)

;;; early-init.el ends here
