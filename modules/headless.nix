{ config, lib, pkgs, ... }:

{
  imports = [
    ../shared/packages.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys =
      [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      discord = import ../pkgs/discord.nix { pkgs = prev; };
    })
    (final: prev: {
      orca-slicer = prev.callPackage ../pkgs/orca-slicer/package.nix {
        withNvidiaGLWorkaround = true;
      };
    })
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
      python3 = prev.python3.override {
        packageOverrides = pyFinal: pyPrev: {
          mpv = pyPrev.mpv.overridePythonAttrs (_: { doCheck = false; });
        };
      };
      vimPlugins = prev.vimPlugins.extend (_: vprev: {
        neotest = vprev.neotest.overrideAttrs (_: { doCheck = false; });
      });
    })
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages =
    [ "python-2.7.18.12" "qtwebengine-5.15.19" "openssl-1.1.1w" "beekeeper-studio-5.5.7" ];

  programs.fish.enable = true;

  time.timeZone = lib.mkDefault "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.mtr.enable = true;

  services.openssh.enable = true;
  services.locate.enable = true;


  system.stateVersion = lib.mkDefault "24.05";
}
