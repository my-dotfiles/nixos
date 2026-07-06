{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/darwin/profiles/macos.nix
  ];

  users.users.yurikon = {
    home = "/Users/yurikon";
    shell = pkgs.fish;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit inputs;
    };
    users.yurikon = import ./home.nix;
  };
}
