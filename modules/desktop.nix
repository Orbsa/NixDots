{ inputs, pkgs, pkgs-stable, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  programs = {
    hyprland.enable = true;
    waybar.enable = true;
  };

  services.pipewire = {
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
      pipewire-pulse."chrome-no-audio" = {
        "pulse.rules" = [{
          matches = [{ "application.name" = "~Chromium.*"; }];
          actions = { quirks = [ "block-source-volume" ]; };
        }];
      };
    };
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
    neowall
    hyprlock
    hyprpicker
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".twilight
    keepassxc
    libnotify
    librewolf
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
    swww
    pkgs-stable.teamspeak_client
    #teamspeak3 # Will this ever work?
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
