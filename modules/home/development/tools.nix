{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.development.tools;
  optionalPkg =
    path:
    let
      value = lib.attrByPath path null pkgs;
    in
    lib.optional (value != null) value;
in
{
  options.myHome.development.tools.enable = lib.mkEnableOption "common development tools";

  config = lib.mkIf cfg.enable {
    home.packages =
      optionalPkg [ "nil" ]
      ++ optionalPkg [ "nixd" ]
      ++ optionalPkg [ "nixfmt-rfc-style" ]
      ++ optionalPkg [ "shfmt" ]
      ++ optionalPkg [ "shellcheck" ]
      ++ optionalPkg [ "statix" ]
      ++ optionalPkg [ "deadnix" ]
      ++ optionalPkg [ "markdown-oxide" ];
  };
}
