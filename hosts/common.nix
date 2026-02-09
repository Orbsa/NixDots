{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../modules/audio.nix
    ../modules/boot.nix
    ../modules/desktop.nix
    ../modules/media.nix
    ../modules/networking.nix
    ../modules/users.nix
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
      [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
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
    powerOnBoot = false;
  };
  boot.extraModprobeConfig = "options bluetooth disable_ertm=1 ";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages =
    [ "python-2.7.18.12" "qtwebengine-5.15.19" "openssl-1.1.1w" ];

  fonts.packages = with pkgs; [ plemoljp-nf ];

  programs = {
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    coolercontrol.enable = true;
  };

  services = {
    getty.autologinUser = "eric";
    openssh.enable = true;
    blueman.enable = true;
    flatpak.enable = true;
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };

  environment.systemPackages = with pkgs; [
    python3
    python2
    comma
    git
    fd
    ripgrep
    home-manager
    vim
    lsd
    wget
    rar
    unrar
    android-tools
    nix-tree
    parallel
    fastfetch
    btop
    busybox
    sqlite
    lm_sensors
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
    smartmontools
    btrfs-progs
    fzf
  ];

  system.stateVersion = "24.05";
}
