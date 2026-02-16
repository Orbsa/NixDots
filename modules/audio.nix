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

  environment.systemPackages = with pkgs; [
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
      w = inputs.nix-gaming.packages.${pkgs.system}.wine-tkg;
    in
    [
      w
      (pkgs.yabridge.override { wineWow64Packages = { yabridge = w; }; })
      (pkgs.yabridgectl.override { wineWow64Packages = { yabridge = w; }; })
    ]
  );
}
