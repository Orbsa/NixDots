#61  Edit this configuration file to define what should be installed on
#61  your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  mesa = pkgs.mesa;
in
{
  imports =
    [ 
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
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };


  programs.fish.enable = true;
  # Boot loader config for configuration.nix:
  boot = {
   loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = false;  # Disabled because using Lanzaboote
      zfsSupport = true;
      efiSupport = true;
      #efiInstallAsRemovable = true;
      mirroredBoots = [
        { devices = [ "nodev"]; path = "/boot"; }
      ];
    };
     systemd-boot.enable = lib.mkForce false;
   };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;  
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

  # NVIDIA
  hardware = {
    nvidia = {
      open = true;
      package =  config.boot.kernelPackages.nvidiaPackages.beta;
      nvidiaSettings = true;
      modesetting.enable = true;
      prime = {
        offload.enable = true;
        nvidiaBusId = "PCI:8:0:0"; # Change this to the correct Bus ID of your Quadro card
        intelBusId = "PCI:1:0:0";  # Change this to the correct Bus ID of your RTX2080 card
      };
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

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
        extraGroups = [ "wheel" "qemu-libvirtd" "libvirtd" "disk" "audio" ];
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    # "libsoup-2.74.3"
    "qtwebengine-5.15.19"
     "openssl-1.1.1w"
  ];

  # For KDE Connect  
  networking.firewall = rec {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  environment.variables = 
    let
      makePluginPath = format:
        (lib.makeSearchPath format [
          "$HOME/.nix-profile/lib"
          "/run/current-system/sw/lib"
          "/etc/profiles/per-user/$USER/lib"
        ])
        + ":$HOME/.${format}";
    in
    {
      DSSI_PATH = makePluginPath "dssi";
      LADSPA_PATH = makePluginPath "ladspa";
      LV2_PATH = makePluginPath "lv2";
      LXVST_PATH = makePluginPath "lxvst";
      VST_PATH = makePluginPath "vst";
      VST3_PATH = makePluginPath "vst3";

      GDK_SCALE = "0.5";
      ENABLE_HDR_WSI=1;
      # __GLX_VENDOR_LIBRARY_NAME = "mesa";
      # __EGL_VENDOR_LIBRARY_FILENAMES = "${mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
    };
  environment.systemPackages = with pkgs;
   [
    (import ./pkgs/noita-entangled-worlds.nix {
      pkgs = pkgs;
    })
    comma
    git
    fd
    ripgrep
    home-manager
    nvidia-docker
    egl-wayland
    vim 
    lsd
    wget
    pulseaudio
    kitty
    foot
    rar
    unrar
    slurp
    android-tools
    hypnotix
    pipewire.jack
    #(pkgs.writeShellScriptBin "reaper" ''
      #${pkgs.pipewire}/bin/pw-jack ${pkgs.reaper}/bin/reaper "$@"
    #'')
    reaper
    reaper-sws-extension
    reaper-reapack-extension
    dxvk.out
    dxvk
    vital
    drumgizmo  # Full drum kit sampler
    hydrogen   # Drum machine/sampler
    infamousPlugins
    lsp-plugins
    surge-XT
    cardinal
    fire
    paulstretch
    rkrlv2
    airwindows-lv2
    distrho-ports
    bshapr
    calf
    bchoppr
    zlsplitter
    zlequalizer
    zlcompressor
    talentedhack
    mooSpace
    artyFX
    boops
    bjumblr
    bslizr
    bankstown-lv2
    uhhyou-plugins 
    thunar
    thunar-volman
    thunderbird
    #gvfs
    nix-tree
    #mtpfs
    #rustdesk
    # davinci-resolve
    gemini-cli
    # opencode
    deluge
    parallel
    r2modman
    grim
    orca-slicer
    sbctl
    claude-code
    blender
    gowall
    cudaPackages.cudatoolkit
    dbeaver-bin
    ghostty
    smartmontools
    plex-desktop
    revanced-cli
    chatterino2
    #bottles

    # Game Mods
    #slipstream
    #lovely-injector

    httpie-desktop
    mullvad-vpn
    mullvad
    wl-clipboard
    cliphist
    lm_sensors
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
    sunshine
    fzf
    hyprlock
    hyprpicker
    hyprland-qtutils
    wofi 
    librewolf
    teamspeak6-client
    pwvucontrol
    coppwr
    qpwgraph
    scream
    keepassxc
    fastfetch
    vesktop
    btop
    fastfetch
    looking-glass-client
    mpv
    yt-dlp
    busybox
    virt-manager
    looking-glass-client
    vscode
    tidal-hifi
    rtkit
    swww
    ncmpcpp
    playerctl
    xdg-utils
    brave
    sqlite
    libnotify
    hoppscotch
    runelite
    hdos
    runescape
    #plex-mpv-shim
    steamtinkerlaunch
    btrfs-progs
    #wineWowPackages.stable
    wineWowPackages.staging
    #wineWowPackages.yabridge
    #winetricks
    #wineWowPackages.waylandFull
    (pkgs.yabridge.override { wine = wineWowPackages.staging; })
    (pkgs.yabridgectl.override { wine = wineWowPackages.staging; })
    lutris
    vulkan-loader
    vulkan-validation-layers
    nvidia-vaapi-driver
    vulkan-tools
    (steam.override { 
      extraProfile = ''
      export VK_ICD_FILENAMES=${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json:$VK_ICD_FILENAMES
      '';
    })
    #plex-media-player 
   ];
    nixpkgs.overlays = [
    (self: super: {
      mpv = super.mpv.override {
        scripts = with self.mpvScripts; [
          mpris sponsorblock-minimal evafast videoclip
        ];
      };
      yabridge = super.yabridge.overrideAttrs (old: rec {
        src = super.fetchFromGitHub {
          owner = "robbert-vdh";
          repo = "yabridge";
          rev = "refs/heads/new-wine10-embedding";
          hash = "sha256-qjyBnwdd/yRIiiAApHyxc/XkkEwB33YP0GpIjG4Upro=";
        };
        patches = super.lib.drop 1 old.patches;
      });
    })
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
  # services.xserver = {
  #  enable = true;
  #  displayManager.gdm.enable = true;
  #  desktopManager.gnome.enable = true;
  # };

  fonts.packages = with pkgs; [
      plemoljp-nf
  ];

  programs = {
    coolercontrol = {
      enable = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
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
   # Enable common container config files in /etc/containers
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    # Enable KVM virtualization.
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
         verbatimConfig = ''
            namespaces = []
           user = "+${builtins.toString config.users.users.eric.uid}"
         '';
       };
    };
  };
  systemd = {
    tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 eric qemu-libvirtd -" # LookingGlass
      "f /dev/shm/scream 0660 eric qemu-libvirtd -" # Scream Audio
      "L /var/lib/libvirt/qemu - - - - /persist/var/lib/libvirt/qemu" #QEMU Confs
      "L /var/lib/flatpak - - - - /persist/var/lib/flatpak " #Flatpak Confs
    ];

    # Scream config
    user.services.scream-ivshmem = {
      enable = true;
      description = "Scream IVSHMEM";
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream-ivshmem-pulse /dev/shm/scream";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "pipewire-pulse.service" ];
    };
  };
services = {
  getty.autologinUser = "eric";
  openssh.enable = true;
  zerotierone = {
    enable = true;
    joinNetworks = [ "af78bf9436e7d202" ]; # Replace with your ZeroTier network ID
  };
  #gvfs.enable = true;
  blueman.enable = true;
  xserver = {
    videoDrivers = [ "nvidia" ];
    dpi = 110;
  };
  # Enable sound.
  pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.quantum" = 512;
      "default.clock.min-quantum" = 512;
      "default.clock.max-quantum" = 512;
    };
  };
  };
  flatpak.enable = true;
  sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    
  };
  mullvad-vpn.enable = true;
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

