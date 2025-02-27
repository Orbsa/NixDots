{ pkgs, ... }: {
  imports = [ ./homebrew.nix ];

  environment = {
  # Hack to make pam-reattach work
    etc."pam.d/sudo_local".text = ''
      # Written by nix-darwin – modified to cache sudo credentials for 15 minutes
      # auth       optional       pam_timestamp.so timeout=15 use_first_pass
      auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
      auth       sufficient     pam_tid.so
    '';
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = with pkgs;
    [
      rustup
      cargo
      nixfmt-rfc-style
      nodejs
      vscode-langservers-extracted
      awscli2
      roslyn-ls
      ripgrep
      fzf
      mpv
      yt-dlp
      ffmpeg
      tmux
    ];
  };

  programs = { 
    zsh.enable = true;
    fish.enable = true;
  };

  ids.gids.nixbld = 350;

  services = {
    sketchybar = {
      enable = false;
      extraPackages = with pkgs; [ jq gh ];
    };
  };

  networking = {
    knownNetworkServices = [ "Wi-Fi" ];
    # dns = [ "9.9.9.9" "1.1.1.1" "8.8.8.8" ];
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.symbols-only
      iosevka-comfy.comfy
      plemoljp-nf
      sketchybar-app-font
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      ".GlobalPreferences"."com.apple.mouse.scaling" = 4.0;
      spaces.spans-displays = false; 
      universalaccess = {
        # FIXME: cannot write universal access
        #reduceMotion = true;
        #reduceTransparency = true;
      };

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        orientation = "bottom";
        dashboard-in-overlay = true;
        largesize = 85;
        tilesize = 50;
        magnification = true;
        launchanim = false;
        mru-spaces = false;
        show-recents = false;
        show-process-indicators = false;
        static-only = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf"; # current folder
        QuitMenuItem = true;
      };

      NSGlobalDomain = {
        NSWindowShouldDragOnGesture = true;
        _HIHideMenuBar = false;
        AppleFontSmoothing = 0;
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        InitialKeyRepeat = 10;
        KeyRepeat = 2;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.0;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.trackpad.scaling" = 2.0;
      };
    };
  };
}
