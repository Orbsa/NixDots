{ inputs, pkgs, pkgs-stable, ... }:

{
  imports = [ ];#./quickshell.nix ];
  xdg.portal.enable = true;

  programs = {
    hyprland = {
      enable = true;
      withUWSM  = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

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
      extraConfig = {
        pipewire."92-high-quality" = {
          "context.properties" = {
            "default.clock.rate" = 96000;
            "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
            "default.clock.quantum" = 512;
            "default.clock.min-quantum" = 128;
            "default.clock.max-quantum" = 4096;
            "default.audio.format" = "S32LE";
          };
        };
        # Uncomment below and comment out above for low-latency profile (rebuild required):
        #pipewire."92-low-latency" = {
        #  "context.properties" = {
        #    "default.clock.rate" = 96000;
        #    "default.clock.allowed-rates" = [ 44100 48000 96000 ];
        #    "default.clock.quantum" = 128;
        #    "default.clock.min-quantum" = 32;
        #    "default.clock.max-quantum" = 256;
        #    "default.audio.format" = "S32LE";
        #  };
        #};
        #pipewire-pulse."chrome-no-audio" = {
          #"pulse.rules" = [{
            #matches = [{ "application.name" = "~Chromium.*"; }];
            #actions = { quirks = [ "block-source-volume" ]; };
          #}];
        #};
      };
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
  };
  users.users.eric.extraGroups = [ "docker" ];


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
    ghostty
    gowall
    grim
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
