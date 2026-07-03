{ inputs, lib, pkgs, username, ... }:

let
  makePluginPath = format:
    (lib.makeSearchPath format [
      "$HOME/.nix-profile/lib"
      "/run/current-system/sw/lib"
      "/etc/profiles/per-user/$USER/lib"
    ]) + ":$HOME/.${format}";
in {
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

   # Real-time audio optimizations via musnix
  musnix = {
    enable = true;
    rtcqs.enable = true;
    rtirq = {
      resetAll = 1;
      prioLow = 0;
      enable = true;
      nameList = "rtc0 snd";
    };
  };

  environment.variables = {
    DSSI_PATH = lib.mkForce (makePluginPath "dssi");
    LADSPA_PATH = lib.mkForce (makePluginPath "ladspa");
    LV2_PATH = lib.mkForce (makePluginPath "lv2");
    LXVST_PATH = lib.mkForce (makePluginPath "lxvst");
    VST_PATH = lib.mkForce (makePluginPath "vst");
    VST3_PATH = lib.mkForce (makePluginPath "vst3");
    JACK_DEFAULT_SERVER = "pipewire";
    # JACK compatibility
    PIPEWIRE_LATENCY = "256/48000";
  };

  users.users.${username}.extraGroups = [ "audio" "jackaudio" ];

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      
      # Enable JACK compatibility
      jack.enable = true;

      extraConfig.pipewire = {
        "99-professional-audio" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 44100 48000 88200 96000 ];
            "default.clock.quantum" = 256;
            "default.clock.min-quantum" = 256;
            "default.clock.max-quantum" = 256;
            "default.clock.force-quantum" = 256;
            "core.daemon" = true;
            "core.name" = "pipewire-0";
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rt";
              args = {
                "nice.level" = -11;
                "rt.prio" = 88;
                "rt.time.soft" = 200000;
                "rt.time.hard" = 200000;
              };
            }
          ];
        };
        "95-line-in-monitor" = {
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
      };
      wireplumber.extraConfig = {
        "52-daw-applications" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "application.name" = "~.*(Bitwig|Studio|JACK).*"; }
              ];
              actions = {
                "update-props" = {
                  "api.alsa.period-size" = 256;
                  "api.alsa.headroom" = 0;
                  "session.suspend-timeout-seconds" = 0;
                };
              };
            }
          ];
        };
      };
    };
  };

  # Enable RTKit for real-time scheduling
  security.rtkit.enable = true;

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
    qjackctl
    crosspipe
    reaper
    jack2
    jack-example-tools
    libjack2
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
    yabridge
    yabridgectl
    ];
    security.pam.loginLimits = [
      { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
      { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
      { domain = "@audio"; item = "nofile"; type = "soft"; value = "99999"; }
      { domain = "@audio"; item = "nofile"; type = "hard"; value = "99999"; }
    ];
}
