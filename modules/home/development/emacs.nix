{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.development.emacs;
in
{
  options.myHome.development.emacs.enable =
    lib.mkEnableOption "Emacs configuration";

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
      extraPackages = epkgs: with epkgs; [
        use-package

	vertico
	marginalia
	orderless
	consult
	which-key

	nix-mode
	magit
      ];
    };
    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      ripgrep
      fd
    ];
    home.sessionVariables = {
     EDITOR = "emacs";
    };
  };
}
