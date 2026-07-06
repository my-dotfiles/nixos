{
  description = "Yurikon macOS nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/macos/home.nix
          ];
        };
      mkDarwin =
        system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.hostPlatform = system;
            }
            ./hosts/macos
            home-manager.darwinModules.home-manager
          ];
        };
    in
    {
      darwinConfigurations = {
        yurikon-macos = mkDarwin "aarch64-darwin";
        yurikon-macos-aarch64 = mkDarwin "aarch64-darwin";
        yurikon-macos-x86_64 = mkDarwin "x86_64-darwin";
      };

      homeConfigurations = {
        yurikon-macos = mkHome "aarch64-darwin";
        yurikon-macos-aarch64 = mkHome "aarch64-darwin";
        yurikon-macos-x86_64 = mkHome "x86_64-darwin";
      };
    };
}
