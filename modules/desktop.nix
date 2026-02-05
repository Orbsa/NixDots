{ config, lib, pkgs, ... }:

{
  programs = {
    hyprland.enable = true;
    waybar.enable = true;
  };

  # For KDE Connect
  networking.firewall = rec {
    allowedTCPPortRanges = [{
      from = 1714;
      to = 1764;
    }];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  environment.systemPackages = with pkgs; [
    blender
    brave
    chatterino2
    claude-code
    cliphist
    dbeaver-bin
    deluge
    foot
    gemini-cli
    ghostty
    gowall
    grim
    hoppscotch
    httpie-desktop
    hypridle
    hyprland-qtutils
    hyprlock
    hyprpicker
    keepassxc
    libnotify
    librewolf
    playerctl
    slurp
    swww
    teamspeak6-client
    thunar
    thunar-volman
    thunderbird
    vesktop
    vscode
    wl-clipboard
    wofi
    xdg-utils
  ];
}
