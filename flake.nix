{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
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
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = { url = "github:musnix/musnix"; };

    nix-gaming = {
      url = "github:torgeir/nix-gaming"; # Wine 9.21
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, nixpkgs, lanzaboote, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.enix = nixpkgs.lib.nixosSystem {
      system = "${system}";
      specialArgs = { inherit inputs; };
      modules = [
# Include the results of the hardware scan. # Include the results of the hardware scan.
        ./enix-hardware.nix
        ./modules/vfio.nix
        inputs.home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.nixvim.homeModules.nixvim
            ];
            extraSpecialArgs = { inherit inputs;};
          };
        }
        lanzaboote.nixosModules.lanzaboote
          ({ pkgs, lib, ... }: {
            environment.systemPackages = [
              # For debugging and troubleshooting Secure Boot.
              pkgs.sbctl
            ];
          })

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
        inputs.musnix.nixosModules.musnix {
          enable = true;
        }
          
        inputs.home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.nixvim.homeModules.nixvim
            ];
            extraSpecialArgs = { inherit inputs;};
          };
        }
      ];
    };
  };
}
