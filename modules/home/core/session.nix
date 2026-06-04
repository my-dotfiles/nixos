{ config, lib, ... }:

let
  cfg = config.myHome.core.session;
in
{
  options.myHome.core.session.enable =
    lib.mkEnableOption "base session paths and environment variables";

  config = lib.mkIf cfg.enable {
    home.sessionPath = [
      "$HOME/.nix-profile/bin"
      "$HOME/.local/state/nix/profile/bin"
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
      "$HOME/.npm-global/bin"
    ];

    home.sessionVariables = {
      HERMES_TUI = "1";
      EDITOR = lib.mkDefault "emacs -nw";
      VISUAL = lib.mkDefault "emacs -nw";
      COLORTERM = "truecolor";
    };
  };
}
