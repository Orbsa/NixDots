{ inputs, lib, pkgs, ... }:

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

  services.pipewire.extraConfig.pipewire."95-line-in-monitor" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "Line In Monitor";
          "capture.props" = {
            "node.name" = "line-in-monitor.capture";
            "media.class" = "Stream/Input/Audio";
            "audio.position" = [ "FL" "FR" ];
            "target.object" = "alsa_input.pci-0000_00_1f.3.analog-stereo";
          };
          "playback.props" = {
            "node.name" = "line-in-monitor.playback";
            "media.class" = "Stream/Output/Audio";
            "audio.position" = [ "FL" "FR" ];
          };
        };
      }
    ];
  };

  systemd.user.services.proto-control = {
    description = "Proto-Control daemon";
    after = [ "pipewire.service" ];
    wantedBy = [ "default.target" ];
    path = [ pkgs.pipewire pkgs.wireplumber ];
    serviceConfig = {
      ExecStart = "${inputs.proto-control.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/proto-control";
      Restart = "on-failure";
    };
  };


  environment.systemPackages = with pkgs; [
    inputs.proto-control.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.callPackage ../pkgs/aida-x.nix { })
    #(pkgs.callPackage ../pkgs/pulse-visualizer.nix { })
    reaper
    reaper-sws-extension
    reaper-reapack-extension
    bitwig-studio
    vital
    cava
    surge-xt
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
    #airwindows
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
    rtkit
    ]
  ++ (
    let
      # helix native needs wine with fsync patches
      w = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg;
      wineWow64PackagesStaging = pkgs.wineWow64Packages // { yabridge = w; };
      # new-wine10-embedding fixes plugin UI rendering; drop first patch (libyabridge-drop-32-bit-support)
      yabridge = (pkgs.yabridge.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "robbert-vdh";
          repo = "yabridge";
          rev = "refs/heads/new-wine10-embedding";
          hash = "sha256-0ju/mfmhutuuPezq1GhiAEiQV/gnfEbrhjX4ydxLX+A=";
        };
        patches = lib.drop 1 old.patches;
      })).override { wineWow64Packages = wineWow64PackagesStaging; };
      yabridgectl = pkgs.yabridgectl.override { wineWow64Packages = wineWow64PackagesStaging; };
    in
    [
      w
      yabridge
      yabridgectl
    ]
  );
}
