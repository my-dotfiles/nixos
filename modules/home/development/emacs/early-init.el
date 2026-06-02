;;; early-init.el --- startup policy -*- lexical-binding: t; -*-

;; Home Manager/Nix provides Emacs packages. Ignore old packages installed
;; under ~/.emacs.d/elpa so they cannot shadow Nix-provided Magit,
;; Transient, magit-section, Vertico, etc.
(setq package-enable-at-startup nil
      package-quickstart nil)

;;; early-init.el ends here
