{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.thinix = nixpkgs.lib.nixosSystem {
        system = "${system}";
        # extraSpecialArgs = {inherit inputs;};
        modules = [
 # Include the results of the hardware scan. # Include the results of the hardware scan.
          ./thinix-hardware.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                inputs.nixvim.homeManagerModules.nixvim
              ];
            };
          }
          #inputs.nixos-cosmic.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
