{ config, lib, pkgs, ... }:

{
  programs = {
    hyprland.enable = true;
    waybar.enable = true;
  };

  # For KDE Connect
  networking.firewall = rec {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  environment.systemPackages = with pkgs; [
    # Terminals
    kitty
    foot
    ghostty
    # Desktop utilities
    wofi
    hyprlock
    hyprpicker
    hyprland-qtutils
    swww
    slurp
    grim
    gowall
    wl-clipboard
    cliphist
    playerctl
    xdg-utils
    libnotify
    # Browsers
    librewolf
    brave
    # File manager
    thunar
    thunar-volman
    # Communication
    thunderbird
    vesktop
    chatterino2
    teamspeak6-client
    # Apps
    keepassxc
    httpie-desktop
    deluge
    claude-code
    gemini-cli
    dbeaver-bin
    vscode
    blender
    hoppscotch
  ];
}
