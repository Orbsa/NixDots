{ inputs, pkgs, pkgs-stable, ... }:

{
  imports = [ ];#./quickshell.nix ];


  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };
  programs = {
    hyprland = {
      enable = true;
      withUWSM  = true;
      # make sure to also set the portal package, so that they are in sync
    };
    waybar.enable = true;
  };

  services = {
    gvfs.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
  };
  users.users.eric.extraGroups = [ "docker" ];


  # gnome-keyring provides a D-Bus secret service so Electron apps (Jagex
  # Launcher, etc.) can use safeStorage for persisting credentials/keys.
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    blender
    brave
    chatterino2
    claude-code
    sox
    cliphist
    dbeaver-bin
    beekeeper-studio
    calibre
    deluge
    foot
    gemini-cli
    xdotool
    ghostty
    gowall
    grim
    tonearm
    teamspeak6-client
    normcap 
    wf-recorder
    hoppscotch
    httpie-desktop
    swayimg
    obs-studio
    element-desktop
    pkgs-stable.plex-mpv-shim
    nemo
    ffmpegthumbnailer
    hypridle
    hyprland-qtutils
    neowall
    hyprlock
    hyprpicker
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".twilight
    keepassxc
    bitwarden-cli
    libnotify
    papirus-folders
    pipewire.jack
    playerctl
    pulseaudio
    pwvucontrol
    coppwr
    qpwgraph
    rustdesk
    slurp
    stirling-pdf
    #lxqt.pcmanfm-qt
    pcmanfm
    thunderbird
    discord
    vscode
    wl-clipboard
    wofi
    xdg-utils
  ];
}
