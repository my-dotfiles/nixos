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
    lib.optional (value != null && lib.meta.availableOn pkgs.stdenv.hostPlatform value) value;
in
{
  options.myHome.development.tools.enable = lib.mkEnableOption "common development tools";

  config = lib.mkIf cfg.enable {
    home.packages =
      optionalPkg [ "cmake" ]
      ++ optionalPkg [ "nil" ]
      ++ optionalPkg [ "nixd" ]
      ++ optionalPkg [ "nixfmt" ]
      ++ optionalPkg [ "shfmt" ]
      ++ optionalPkg [ "shellcheck" ]
      ++ optionalPkg [ "statix" ]
      ++ optionalPkg [ "deadnix" ]
      ++ optionalPkg [ "gcc" ]
      ++ optionalPkg [ "clang-tools" ]
      ++ optionalPkg [ "jdt-language-server" ]
      ++ optionalPkg [ "markdown-oxide" ]
      ++ optionalPkg [ "pyright" ]
      ++ optionalPkg [ "ruff" ]
      ++ optionalPkg [ "rustc" ]
      ++ optionalPkg [ "cargo" ]
      ++ optionalPkg [ "rustfmt" ]
      ++ optionalPkg [ "clippy" ]
      ++ optionalPkg [ "yaml-language-server" ];
  };
}
