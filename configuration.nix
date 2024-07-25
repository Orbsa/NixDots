#61  Edit this configuration file to define what should be installed on
#61  your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    ];
  home-manager = { 
    users = {
      "eric" = import ./home.nix;
    };
  };
  nix.nixPath =
    [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    
      "nixos-config=/persist/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://hyprland.cachix.org" 
      "https://cosmic.cachix.org/"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" 
    ];
  };

  # Boot loader config for configuration.nix:
  boot.loader = {
    efi = {
    canTouchEfiVariables = true;
    };
    grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      # efiInstallAsRemovable = true;
      mirroredBoots = [
        { devices = [ "nodev"]; path = "/boot"; }
      ];
    };

  };

  networking = {
    hostName = "enix"; # Define your hostname.
    hostId = "6241ca71"; 
  };

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  services = {
    #desktopManager.cosmic.enable = true;
    #displayManager.cosmic-greeter.enable = true;
    # Enable sound.
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    #flatpak.enable = true;
  };
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
  #environment.variables = { GDK_SCALE = "0.5"; };

  # Bluetooth
  # https://nixos.wiki/wiki/Bluetooth
  # Don't power up the default Bluetooth controller on boot
  boot.extraModprobeConfig = "options bluetooth disable_ertm=1 ";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    mutableUsers = false;
    users = {
      root = {
        initialHashedPassword = "$y$j9T$U7UbLkyC3ehiUSraLjjTF0$VMAl8LHs0U.QfZrpU5UQ/HaPtnoOOWv3TmjwdAWsRy8";
      };
      eric = {
        isNormalUser = true;
        createHome = true;
        initialHashedPassword = "$y$j9T$LGtqcLijoBEb9Ap8WVeAZ0$7ZMSUzOEVrFsF4R2J8Z.aZc6e7WPBY/OAYnoMBZNM41";
        extraGroups = [ "wheel" "qemu-libvirtd" "libvirtd" "disk" ];
        uid = 1000;
        home = "/home/eric";
        shell = pkgs.fish;
        #useDefaultShell = true;
        #openssh.authorizedKeys.keys = [ "${AUTHORIZED_SSH_KEY}" ];
      };
    };
  };
  # Fuck entering my passwords
  security.sudo.wheelNeedsPassword = false;
  # Auto Login
  services.getty.autologinUser = "eric";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs;
   [
    git
    fd
    ripgrep
    home-manager
    egl-wayland
    vim 
    wget
    lsd
    pulseaudio
    kitty
    foot
    dolphin
    slurp
    grim
    grc
    nm-aplet
    mullvad-vpn
    mullvad
    wl-clipboard
    cliphist
    hyprlock
    wofi 
    librewolf
    teamspeak_client
    pwvucontrol
    coppwr
    qpwgraph
    scream
    keepassxc
    fastfetch
    vesktop
    looking-glass-client
    mpv
    yt-dlp
    busybox
    virt-manager
    looking-glass-client
    tidal-hifi
    rtkit
    swww
    ncmpcpp
    playerctl
    xdg-utils
    sqlite
    libnotify
    hoppscotch
    runelite
    plex-mpv-shim
    steamtinkerlaunch
    btrfs-progs
    wineWowPackages.stable
    wineWowPackages.waylandFull
    winetricks
    lutris
    vulkan-tools
    #plex-media-player 
   ];
   #nixpkgs.overlays = [(final: prev: {
     #plex-media-player= prev.plex-media-player.override (old: {
         #mpv =  old.mpv.overrideAttrs ( prevo: {
           #src = prev.fetchFromGitHub {
             #owner = "mpv-player";
             #repo = "mpv";
             #rev = "v0.37.0";
             #hash="sha256-izAz9Iiam7tJAWIQkmn2cKOfoaog8oPKq4sOUtp1nvU=";
           #};
       #});
     #});
   #})];
  services.mullvad-vpn.enable = true;
  #services.xserver = {
  #  enable = true;
  #  displayManager.gdm.enable = true;
  #  desktopManager.gnome.enable = true;
  #};

  fonts.packages = with pkgs; [
      plemoljp-nf
  ];

  programs = {
    fish.enable = true;
    dconf.enable = true;
    nm-applet.enable = true;
    steam.enable = true;
    waybar.enable = true;
    hyprland.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Looking Glass
  # Enable virtualisation programs. These will be used by virt-manager to run your VM.
  virtualisation = {
     libvirtd = {
       enable = true;
       extraConfig = ''
         user="eric"
       '';

       # Don't start any VMs automatically on boot.
       onBoot = "ignore";
       # Stop all running VMs on shutdown.
       onShutdown = "shutdown";

       qemu = {
         package = pkgs.qemu_kvm;
         ovmf.enable = true;
         verbatimConfig = ''
            namespaces = []
           user = "+${builtins.toString config.users.users.eric.uid}"
         '';
       };
    };
  };
  systemd = {
    #tmpfiles.rules = [ ];

  };
  services = {
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
    upower.enable = true;
    openssh.enable = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  #system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}

