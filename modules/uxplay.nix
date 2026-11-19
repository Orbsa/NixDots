{ config, lib, pkgs, ... }:

let
  cfg = config.my.uxplay;

  # `-async` takes an optional delay in milliseconds. It is followed by `-as`
  # when no delay is set; `-as` is non-numeric, so UxPlay does not consume it
  # as the delay.
  syncArgs =
    lib.optionals cfg.sync
      ([ "-async" ] ++ lib.optional (cfg.syncDelayMs != null) (toString cfg.syncDelayMs));

  instancePort = i: cfg.basePort + 3 * i;

  instanceArgs = i: inst: [
    "${cfg.package}/bin/uxplay"
    "-nh"
    "-n" inst.name
    "-p" (toString (instancePort i))
    "-vs" "0"
  ] ++ syncArgs ++ [
    "-as" "pulsesink device=${cfg.sinkName}"
  ] ++ lib.optionals (inst.mac != null) [ "-m" inst.mac ] ++ cfg.extraArgs;

  instances = lib.imap0 (i: inst: { index = i; inherit inst; }) cfg.instances;

  serviceName = i: if i == 0 then "uxplay" else "uxplay-${toString (i + 1)}";

  allPorts =
    lib.concatMap
      (i: [ (instancePort i) (instancePort i + 1) (instancePort i + 2) ])
      (lib.range 0 (lib.length cfg.instances - 1));
in
{
  options.my.uxplay = {
    enable = lib.mkEnableOption "UxPlay AirPlay receiver (audio only)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.uxplay;
      defaultText = lib.literalExpression "pkgs.uxplay";
    };

    instances = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name advertised to AirPlay clients.";
          };

          mac = lib.mkOption {
            type = lib.types.nullOr (lib.types.strMatching "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}");
            default = null;
            description = ''
              Device ID / MAC for this instance (`-m`). UxPlay rejects a
              mDNS name conflict when two instances share a Device ID, so every
              instance after the first needs its own. Leave null only for the
              first instance, which then uses the host NIC's MAC.
            '';
          };
        };
      });
      default = [ { name = "${config.networking.hostName} AirPlay"; } ];
      description = ''
        One AirPlay endpoint per entry. UxPlay accepts a single sender per
        endpoint — a second sender gets `409 Conflict: Server is connected to
        another client` until the first disconnects — so concurrent senders
        need separate entries. All instances play into `sinkName`, so PipeWire
        mixes them into one output.
      '';
    };

    basePort = lib.mkOption {
      type = lib.types.port;
      default = 7000;
      description = ''
        Base AirPlay port of the first instance. Instance i uses
        `basePort + 3*i` and the following two ports, for both TCP and UDP.
      '';
    };

    sinkName = lib.mkOption {
      type = lib.types.str;
      default = "airplay";
      description = "PipeWire sink UxPlay plays into.";
    };

    createSink = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Create a loopback sink named `sinkName` whose playback side follows the
        default output, so AirPlay audio is audible and can be routed
        independently of other application streams.
      '';
    };

    sync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Timestamp-based A/V sync for audio-only (ALAC) mode (`-async`).

        Without it UxPlay plays ALAC packets as soon as they arrive
        (`sync=false`), so server audio runs ahead of video that stays on the
        client. Once every audio pipeline starts, `-async` renders each packet
        at the client's NTP timestamp instead. Cost: pause/track changes take
        up to ~2 s to reach the server.
      '';
    };

    syncDelayMs = lib.mkOption {
      type = lib.types.nullOr lib.types.float;
      default = null;
      description = ''
        Extra audio delay for `-async`, in milliseconds. Positive delays the
        server audio; negative advances it. Must satisfy -1000 < x < 1000.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments appended to the UxPlay command line.";
    };
  };

  config = lib.mkIf cfg.enable {
    # UxPlay registers _airplay._tcp and _raop._tcp through avahi-compat.
    # Publishing from an unprivileged user is disabled by default on NixOS.
    services.avahi = {
      enable = true;
      openFirewall = true;
      settings.publish = {
        "disable-publishing" = false;
        "disable-user-service-publishing" = false;
        "publish-addresses" = true;
      };
    };

    # PipeWire has no null-sink module. A loopback whose capture side is an
    # Audio/Sink *is* the virtual sink, and its playback side (a plain playback
    # stream) is linked to the default output by WirePlumber. This must be one
    # node, not a null sink plus a loopback targeting it by name: modules load
    # before context.objects, so a name target does not resolve yet and
    # WirePlumber falls back to the default *source* (the mic).
    services.pipewire.extraConfig.pipewire = lib.mkIf cfg.createSink {
      "96-uxplay-sink" = {
        "context.modules" = [
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "AirPlay";
              "capture.props" = {
                "node.name" = cfg.sinkName;
                "node.description" = "AirPlay";
                "media.class" = "Audio/Sink";
                "audio.position" = [ "FL" "FR" ];
              };
              "playback.props" = {
                "node.name" = "${cfg.sinkName}.playback";
                "media.class" = "Stream/Output/Audio";
                "audio.position" = [ "FL" "FR" ];
              };
            };
          }
        ];
      };
    };

    networking.firewall = {
      allowedTCPPorts = allPorts;
      allowedUDPPorts = allPorts;
    };

    # Runs inside eric's user manager so it can reach the session PipeWire.
    # nixpkgs' GStreamer good plugins are built without the pipewire plugin,
    # so the sink is reached through pipewire-pulse's PulseAudio socket.
    systemd.user.services = lib.listToAttrs (map (entry: {
      name = serviceName entry.index;
      value = {
        description = "UxPlay AirPlay receiver (${entry.inst.name})";
        wantedBy = [ "default.target" ];
        after = [ "pipewire-pulse.service" ];
        wants = [ "pipewire-pulse.service" ];
        serviceConfig = {
          ExecStart = lib.escapeShellArgs (instanceArgs entry.index entry.inst);
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    }) instances);
  };
}
