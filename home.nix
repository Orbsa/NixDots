{ config, pkgs, ... }:

{
  imports = [
    ./config/programs
  ];
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "eric";
    homeDirectory = "/home/eric";

    # Packages that should be installed to the user profile.
    packages = with pkgs; [
      htop
      fortune
      prismlauncher
      papirus-folders
    ];
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "lavender";
      };
    };
    #cursorTheme = {
      #name = "Catppuccin-Mocha-Light-Cursors";
    #  package = pkgs.catppuccin-cursors.mochaLight;
    #};
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

  #home.pointerCursor = {
  #gtk.enable = true;
  ##name = "Catppuccin-Mocha-Light-Cursors";
  #package = pkgs.catppuccin-cursors.mochaLight;
    #size = 16;
  #};

  home.shellAliases = {
    ls = "lsd";
    vim = "nvim";
    eZ = "cd ~/.config/nix; nvim home.nix";
    Ze = "sudo nixos-rebuild --flake /home/eric/.config/nix/ switch";
  };

  #dconf.settings = {
    #"org/gnome/desktop/interface" = {
    #gtk-theme = "Breeze-Dark";
    #color-scheme = "prefer-dark";
    #};
  #};

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;
    nixvim.enable = true;
    fish = {
      enable = true;
      plugins = [
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      ];
    };
  };
  services = {
    mpd = {
      enable = true;
      musicDirectory = "~/Music";
      extraConfig = ''
        audio_output {
          type "pipewire"
          name "My PipeWire Output"
        }
      '';
    };
   # mopidy = let
   #   mopidyPackagesOverride = pkgs.mopidyPackages.overrideScope (prev: final: { extraPkgs = pkgs: [ 
   #     pkgs.yt-dlp 
   #     (pkgs.python3.withPackages (p: with p; [
   #       pygobject3 gst-python 
   #     ]))
   #   ];});
   # in {
   #   enable = true;
   #   extensionPackages = with mopidyPackagesOverride; [
   #     mopidy-mpd
   #     mopidy-tidal
   #     mopidy-podcast
   #     mopidy-soundcloud
   #     mopidy-notify
   #     mopidy-youtube
   #   ];
   #   settings = {
   #     youtube = {
   #       youtube_dl_package = "yt_dlp";
   #     };
   #     mpd = {
   #       enabled = true;
   #       hostname = "127.0.0.1";
   #     };
   #     tidal = {
   #       enabled = true;
   #       quality = "LOSSLESS";
   #       #playlist_cache_refresh_secs = 0
   #       #lazy = true
   #       login_method = "AUTO";
   #       auth_method = "PKCE";
   #       login_server_port = 8989;
   #       #client_id =
   #     };
   #     soundcloud = {
   #       enabled = true;
   #       explore_songs = 25;
   #       auth_token = "3-35204-852097828-A8Y4EsxCgpgtmdV";
   #     };
   #   };
   # };
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
    plex-mpv-shim = {
      enable = true;
      settings = {
        mpv_ext = true;
      };
    };
  };
}
