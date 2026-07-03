{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../shared/packages.nix
    ../modules/audio.nix
    ../modules/boot.nix
    ../modules/desktop.nix
    ../modules/media.nix
    ../modules/networking.nix
    ../modules/users.nix
    inputs.agenix.nixosModules.default
    ../modules/tailscale.nix
  ];

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/persist/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys =
      [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "bambu-studio.cachix.org-1:6Ygd0p7L9jY6dg/v6TzR1XrwqQa9C42ATLwsBmxD8JM=" ];
    max-jobs = 8;
    cores = 4;
  };

  programs.fish.enable = true;

  time.timeZone = "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
    options snd-intel-dspcfg dsp_driver=1
    options snd-hda-intel power_save=0 power_save_controller=N
  '';

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

  fonts.packages = with pkgs; [
    plemoljp-nf
    google-fonts
    nerd-fonts.blex-mono
    ibm-plex
  ];

  programs = {
    dconf.enable = true;
    mtr.enable = true;
    coolercontrol.enable = true;
  };

  services = {
    locate = {
      enable = true;
    };

    getty.autologinUser = "eric";
    openssh.enable = true;
    blueman.enable = true;
    flatpak.enable = true;
    geoclue2.enable = true;
    #sunshine = {
      #enable = true;
      #autoStart = true;
      #capSysAdmin = true;
      #openFirewall = true;
    #};
  };

  # Persist flatpak data across ephemeral root rollbacks
  systemd.tmpfiles.rules = [
    "d /persist/var/lib/flatpak 0755 root root -"
    "L /var/lib/flatpak - - - - /persist/var/lib/flatpak"
  ];


  system.stateVersion = "24.05";
}
