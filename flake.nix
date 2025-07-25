{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-colors.url = "github:misterio77/nix-colors";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up to date or simply don't specify the nixpkgs input  
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.enix = nixpkgs.lib.nixosSystem {
      system = "${system}";
      # extraSpecialArgs = {inherit inputs;};
      modules = [
# Include the results of the hardware scan. # Include the results of the hardware scan.
        ./enix-hardware.nix
        ./modules/vfio.nix
        inputs.home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.nixvim.homeManagerModules.nixvim
            ];
            extraSpecialArgs = { inherit inputs;};
          };
        }
        ./configuration.nix
      ];
    };

    nixosConfigurations.thinix = nixpkgs.lib.nixosSystem {
      system = "${system}";
      # extraSpecialArgs = {inherit inputs;};
      modules = [
# Include the results of the hardware scan. # Include the results of the hardware scan.
        ./thinix-hardware.nix
        ./configuration.nix
        inputs.home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.nixvim.homeManagerModules.nixvim
            ];
            extraSpecialArgs = { inherit inputs;};
          };
        }
      ];
    };
  };
}
