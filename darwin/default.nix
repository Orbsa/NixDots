{ pkgs, ... }: {
  imports = [ ./homebrew.nix ];

  power.sleep.display = 15;

  environment = {
    etc."pam.d/sudo_local".text = ''
      # Written by nix-darwin - modified to cache sudo credentials for 15 minutes
      auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
      auth       sufficient     pam_tid.so
    '';
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = with pkgs; [
      jujutsu
      jjui
      claude-code
      mediainfo
      tmux-sessionizer
      gh
      k9s
      e1s
      fd
      postgresql
      rustup
      cargo
      nixfmt-rfc-style
      nodejs
      vscode-langservers-extracted
      vscode-extensions.vadimcn.vscode-lldb
      awscli2
      stu
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

  networking = { knownNetworkServices = [ "Wi-Fi" ]; };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.symbols-only
      plemoljp-nf
      sketchybar-app-font
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    primaryUser = "ebell";
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      ".GlobalPreferences"."com.apple.mouse.scaling" = 4.0;
      spaces.spans-displays = false;
      universalaccess = { };

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
        FXDefaultSearchScope = "SCcf";
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
