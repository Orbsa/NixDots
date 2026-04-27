{ inputs, pkgs, pkgs-stable, ... }:

{
  imports = [ ./quickshell.nix ];
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
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig = {
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 44100;
            "default.clock.quantum" = 512;
            "default.clock.min-quantum" = 512;
            "default.clock.max-quantum" = 512;
          };
        };
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
    hoppscotch
    httpie-desktop
    swayimg
    element-desktop
    spacedrive
    plex-mpv-shim


    hypridle
    hyprland-qtutils
    neowall
    hyprlock
    hyprpicker
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".twilight
    keepassxc
    bitwarden-cli
    libnotify
    librewolf
    chromium
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
    pkgs-stable.teamspeak_client
    #teamspeak3 # Will this ever work?
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
