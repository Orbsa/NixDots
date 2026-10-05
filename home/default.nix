{ pkgs, lib, osConfig, ... }:

let
  audioEnabled = osConfig.services.pipewire.enable or false;
in {
  imports = [
    ./headless.nix
    ./gtk.nix
    ./media.nix
    ./printing.nix
    ./gaming.nix
    ./mimeapps.nix
  ];

  home.sessionVariables.TERM = "xterm";

  home = {
    username = "eric";
    homeDirectory = "/home/eric";
    stateVersion = "24.05";
    shellAliases = {
      ls = "lsd";
      vim = "nvim";
      eZ = "cd ~/.config/nix; nvim home.nix";
      Ze = "sudo nixos-rebuild --flake /home/eric/.config/nix/ switch";
      yt = "yt-dlp --cookies-from-browser firefox:~/.config/zen --extractor-args \"youtube:player_client=web_embedded\"";
    };
  };

  xdg = {
    # Steam Linux Runtime (pressure-vessel), Flatpak and other sandboxes only see
    # host fonts via /run/host/fonts (= host /usr/share/fonts, absent on NixOS)
    # and /run/host/user-fonts (= ~/.local/share/fonts). NixOS keeps system fonts
    # in the store and registers them through /etc/fonts, so sandboxed apps get no
    # emoji font at all and render tofu. Stage one here.
    dataFile."fonts/NotoColorEmoji.ttf" = {
      source = "${pkgs.noto-fonts-color-emoji}/share/fonts/noto/NotoColorEmoji.ttf";
      # The file predates home-manager management (and its store path changes
      # with every nixpkgs bump); clobber it instead of failing the switch.
      force = true;
    };

    configFile = lib.mkIf audioEnabled {
      "yabridgectl/config.toml".text = ''
        plugin_dirs = [
          '/home/eric/.wine/drive_c/Program Files/Common Files',
          '/home/eric/.wine/drive_c/VST2',
          '/home/eric/.wine/drive_c/VST3',
        ]
        vst2_location = 'centralized'
        no_verify = false
        blacklist = []
      '';
    };
  };

  services.dunst.enable = true;
  services.kdeconnect.enable = true;
}
