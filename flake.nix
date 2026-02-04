{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-colors.url = "github:misterio77/nix-colors";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = { url = "github:musnix/musnix"; };

    nix-gaming = {
      url = "github:torgeir/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-zsh-fzf-tab.url =
      "github:nixos/nixpkgs/8193e46376fdc6a13e8075ad263b4b5ca2592c03";
  };

  outputs = { self, nixpkgs, lanzaboote, ... }@inputs:
  let
    linuxSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${linuxSystem};
    pkgs-unstable-linux = import inputs.nixpkgs-unstable {
      system = linuxSystem;
      config.allowUnfree = true;
    };
    pkgs-unstable-darwin = import inputs.nixpkgs-unstable {
      system = darwinSystem;
      config.allowUnfree = true;
    };
  in
  {
    nixosConfigurations.enix = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/enix.nix
        inputs.home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.nixvim.homeModules.nixvim
            ];
            extraSpecialArgs = {
              inherit inputs;
              pkgs-unstable = pkgs-unstable-linux;
            };
          };
        }
      ];
    };

    nixosConfigurations.thinix = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/thinix.nix
        inputs.musnix.nixosModules.musnix
        { musnix.enable = true; }
        inputs.home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              inputs.nixvim.homeModules.nixvim
            ];
            extraSpecialArgs = {
              inherit inputs;
              pkgs-unstable = pkgs-unstable-linux;
            };
          };
        }
      ];
    };

    darwinConfigurations."KN72DN4D3W" = inputs.darwin.lib.darwinSystem {
      system = darwinSystem;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.nix-index-database.darwinModules.nix-index
        ./darwin
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;

          system = {
            stateVersion = 4;
            configurationRevision = self.rev or self.dirtyRev or null;
          };

          users.users."ebell" = {
            home = "/Users/ebell";
            shell = pkgs.fish;
          };

          networking = {
            computerName = "KN72DN4D3W";
            hostName = "KN72DN4D3W";
            localHostName = "KN72DN4D3W";
          };

          nix = {
            package = pkgs.nixVersions.stable;
            gc.automatic = false;
            settings = {
              trusted-users = [ "root" "ebell" ];
              extra-platforms = [ "x86_64-linux" "aarch64-linux" ];
              allowed-users = [ "ebell" ];
              experimental-features = [ "nix-command" "flakes" ];
              warn-dirty = false;
              auto-optimise-store = false;
            };
          };
        })
        inputs.home-manager-darwin.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs;
              pkgs-zsh-fzf-tab =
                import inputs.nixpkgs-zsh-fzf-tab { system = darwinSystem; };
              pkgs-unstable = pkgs-unstable-darwin;
            };
            users."ebell" = { ... }: {
              imports = [ ./home/mac.nix ];
            };
          };
        }
      ];
    };
  };
}
