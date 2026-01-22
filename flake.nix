{
  description = "Work Nix Mac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-zsh-fzf-tab.url =
      "github:nixos/nixpkgs/8193e46376fdc6a13e8075ad263b4b5ca2592c03";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      nixpkgsConfig = {
        allowUnfree = true;
        allowUnsupportedSystem = false;
      };
      # overlays = with inputs; [];
      user = "ebell";
      hostname = "KN72DN4D3W";
      system = "aarch64-darwin";
    in {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
      # nix-darwin with home-manager for macOS
      darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
        inherit system;
        # makes all inputs availble in imported files
        specialArgs = { inherit inputs; };
        modules = [
          inputs.nix-index-database.darwinModules.nix-index
          ./darwin
          ({ pkgs, inputs, ... }: {
            nixpkgs.config = nixpkgsConfig;
            # nixpkgs.overlays = overlays;

            system = {
              stateVersion = 4;
              configurationRevision = self.rev or self.dirtyRev or null;
            };

            users.users.${user} = {
              home = "/Users/${user}";
              shell = pkgs.fish;
            };

            networking = {
              computerName = hostname;
              hostName = hostname;
              localHostName = hostname;
            };

            nix = {
              settings = {
                trusted-users = [ "root" "ebell" ];
                extra-platforms = [ "x86_64-linux" "aarch64-linux" ];
              };

              # enable flakes per default
              package = pkgs.nixVersions.stable;
              gc = {
                automatic = false;
              };
              settings = {
                allowed-users = [ user ];
                experimental-features = [ "nix-command" "flakes" ];
                warn-dirty = false;
                # produces linking issues when updating on macOS
                # https://github.com/NixOS/nix/issues/7273
                auto-optimise-store = false;
              };
            };
          })
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # makes all inputs available in imported files for hm
              extraSpecialArgs = {
                inherit inputs;
                pkgs-zsh-fzf-tab =
                  import inputs.nixpkgs-zsh-fzf-tab { inherit system; };
              };
              users.${user} = { ... }:
                with inputs; {
                  imports = [ ./home-manager ];
                  home.stateVersion = "23.11";
                };
            };
          }
        ];
      };
    };
}
