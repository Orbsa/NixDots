{ config, lib, pkgs, ... }:

let
  makePluginPath = format:
    (lib.makeSearchPath format [
      "$HOME/.nix-profile/lib"
      "/run/current-system/sw/lib"
      "/etc/profiles/per-user/$USER/lib"
    ]) + ":$HOME/.${format}";
in {
  environment.variables = {
    DSSI_PATH = makePluginPath "dssi";
    LADSPA_PATH = makePluginPath "ladspa";
    LV2_PATH = makePluginPath "lv2";
    LXVST_PATH = makePluginPath "lxvst";
    VST_PATH = makePluginPath "vst";
    VST3_PATH = makePluginPath "vst3";
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
    (pkgs.callPackage ../pkgs/aida-x.nix { })
    reaper
    reaper-sws-extension
    reaper-reapack-extension
    bitwig-studio
    vital
    surge-XT
    carla
    drumgizmo
    hydrogen
    sfizz
    sfizz-ui
    x42-gmsynth
    dragonfly-reverb
    fluidsynth
    fluida-lv2
    infamousPlugins
    lsp-plugins
    cardinal
    fire
    paulstretch
    rkrlv2
    airwindows
    airwindows-lv2
    x42-avldrums
    x42-plugins
    distrho-ports
    bshapr
    calf
    bchoppr
    zlsplitter
    zlequalizer
    zlcompressor
    talentedhack
    mooSpace
    artyFX
    boops
    bjumblr
    bslizr
    bankstown-lv2
    uhhyou-plugins
    # PipeWire GUI tools
    pwvucontrol
    coppwr
    qpwgraph
    # Audio utilities
    rtkit
    pulseaudio
    pipewire.jack
  ];
}
