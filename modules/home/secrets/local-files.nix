{ config, lib, ... }:

let
  cfg = config.myHome.secrets.localFiles;
in
{
  options.myHome.secrets.localFiles.enable = lib.mkEnableOption "local-only secret file hooks";

  config = lib.mkIf cfg.enable {
    programs.bash.bashrcExtra = ''
      [[ -f "$HOME/.config/secrets/api-keys.bash" ]] && source "$HOME/.config/secrets/api-keys.bash"
    '';

    programs.fish.interactiveShellInit = ''
      test -f "$HOME/.config/secrets/api-keys.fish"; and source "$HOME/.config/secrets/api-keys.fish"
    '';
  };
}
