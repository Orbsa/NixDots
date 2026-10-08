{ config, lib, pkgs, ... }:

# Media over QUIC relay for the Multiplex player.
#
# Why this exists: the player used to re-encode to HLS and serve segment files
# out of a directory on this host. MoQ replaces that with a relay — the encoder
# publishes ONE broadcast and every viewer subscribes to that same broadcast, so
# the shared playhead is a property of the topology instead of a playlist that
# clients race to follow. Nothing is stored as a file.
#
# The relay terminates its own TLS, because WebTransport is QUIC over UDP and no
# reverse proxy can carry it — nginx on 10.0.0.3 terminates HTTP/3 itself and can
# only pass HTTP/1.1 or HTTP/2. That is also why moq.orbsa.net must resolve to
# THIS host rather than to the proxy: the browser has to reach the relay's own
# QUIC listener, on its own forwarded port.
#
# The certificate is deliberately not issued on this host. plix's /, /etc and
# /var are tmpfs, so an ACME client here would re-order a certificate on every
# boot; and the only working Cloudflare DNS-01 credentials live on the proxy.
# NPMplus therefore owns moq.orbsa.net's certificate and a timer here pulls it,
# exactly as mail-cert-sync does for poste.io. The material lands on /home (its
# own persistent ext4 mount) rather than /persist, because /persist is
# root-owned and the sync runs as an unprivileged user.
let
  cfg = config.my.moqRelay;

  moq = pkgs.callPackage ../pkgs/moq.nix { };

  certName = "npm-${toString cfg.certificateId}";
  livePath = "/data/tls/certbot/live/${certName}";

  relayConfig = pkgs.writeText "moq-relay.toml" ''
    [listen]
    bind = "[::]:8443"

    [listen.tls]
    cert = "${cfg.tlsDir}/fullchain.pem"
    key = "${cfg.tlsDir}/privkey.pem"

    # Trusted local workers: the encoder publishes over this loopback listener
    # with no TLS and no UDP, so publishing never depends on the certificate and
    # never leaves the host.
    [listen.tcp]
    bind = "127.0.0.1:4444"

    # TCP on the same port number carries the WebSocket fallback that Safari and
    # any UDP-blocked client races the QUIC connection against, plus /health,
    # /announced and the certificate fingerprint for local development.
    [web.https]
    listen = "[::]:8443"
    cert = "${cfg.tlsDir}/fullchain.pem"
    key = "${cfg.tlsDir}/privkey.pem"

    # Operational endpoints stay on loopback: /metrics, /sessions, /nodes.
    [internal]
    listen = "127.0.0.1:9101"

    # Every session is admitted by the auth server below, so a viewer needs a
    # token minted against their own session — the feed is as gated as the site.
    [auth]
    url = "http://127.0.0.1:4440/"

    # Late joiners: the relay answers a new subscriber out of this cache, which
    # is what makes joining a film already in progress show video immediately
    # rather than waiting for the next keyframe from the encoder.
    [cache]
    capacity = "1GiB"
    duration = "30s"
  '';

  certSync = pkgs.writeShellApplication {
    name = "moq-cert-sync";
    runtimeInputs = with pkgs; [
      openssh
      coreutils
      diffutils # cmp — the certificate/key match check
      openssl
    ];
    # SC2029: expanding the paths client-side is the intent — they name files the
    # remote side already has, not values meant for interpolation there.
    excludeShellChecks = [ "SC2029" ];
    text = ''
      # Pull moq.orbsa.net's certificate from the proxy that owns it.
      #
      # The certificate is short-lived (Let's Encrypt "shortlived", ARI-driven,
      # ~7 days), so this runs on a timer as well as at boot. A failed pull must
      # never remove what is already installed: the relay hot-reloads these files
      # and can keep serving the previous certificate until the next attempt.
      set -euo pipefail

      TLS_DIR=${lib.escapeShellArg cfg.tlsDir}
      SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)

      log() { printf '%s %s\n' "$(date -Is)" "$*"; }

      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT

      log "fetching ${certName} from the proxy"
      ssh "''${SSH_OPTS[@]}" proxy docker exec npmplus cat ${livePath}/fullchain.pem > "$work/fullchain.pem"
      ssh "''${SSH_OPTS[@]}" proxy docker exec npmplus cat ${livePath}/privkey.pem > "$work/privkey.pem"

      # A mismatched pair is a broken TLS listener, and the listener is the only
      # way in: refuse rather than install it.
      openssl x509 -in "$work/fullchain.pem" -noout -pubkey > "$work/cert.pub"
      openssl pkey -in "$work/privkey.pem" -pubout > "$work/key.pub"
      if ! cmp -s "$work/cert.pub" "$work/key.pub"; then
        log "FATAL: fetched certificate and key do not match — leaving the installed pair untouched"
        exit 1
      fi

      # The relay must never be handed a certificate for the wrong name.
      if ! openssl x509 -in "$work/fullchain.pem" -noout -ext subjectAltName | grep -q "${cfg.domain}"; then
        log "FATAL: certificate does not cover ${cfg.domain} — refusing to install"
        exit 1
      fi

      if [ -f "$TLS_DIR/fullchain.pem" ] && cmp -s "$work/fullchain.pem" "$TLS_DIR/fullchain.pem"; then
        log "already current; nothing to do"
        exit 0
      fi

      log "installing the renewed certificate for ${cfg.domain}"
      install -d -m 0750 "$TLS_DIR"
      install -m 0644 "$work/fullchain.pem" "$TLS_DIR/fullchain.pem.new"
      install -m 0600 "$work/privkey.pem" "$TLS_DIR/privkey.pem.new"
      # Rename into place: the relay watches these paths and must never read a
      # half-written file.
      mv "$TLS_DIR/fullchain.pem.new" "$TLS_DIR/fullchain.pem"
      mv "$TLS_DIR/privkey.pem.new" "$TLS_DIR/privkey.pem"
      log "done — ${cfg.domain} certificate refreshed"
    '';
  };
in
{
  options.my.moqRelay = {
    enable = lib.mkEnableOption "the Media over QUIC relay that feeds the Multiplex player";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "moq.orbsa.net";
      description = ''
        Name the relay serves. It must resolve to this host (VyOS owns the
        orbsa.net zone, whose wildcard points every other name at the proxy) and
        must match the certificate an ACME client has issued for it.
      '';
    };

    certificateId = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        NPMplus certificate id for moq.orbsa.net — the lineage lives at
        /data/tls/certbot/live/npm-<id> inside the npmplus container on CT 200.
      '';
    };

    tlsDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/admin/.config/moq-relay/tls";
      description = "Where the synced certificate and key are installed.";
    };

    keyDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/admin/.config/moq-relay";
      description = ''
        Directory holding the relay's JWT key material: `private.jwk` signs
        viewer tokens (read by the player server) and `public.jwk` verifies them
        (read by the auth server). Provisioned once; see the README.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = ''
        User the relay, the auth server and the certificate sync run as — the
        same account the player service uses, and the one whose ~/.ssh carries
        the `proxy` alias the sync needs.
      '';
    };

    cacheCapacity = lib.mkOption {
      type = lib.types.str;
      default = "1GiB";
      description = "Bytes of recent media the relay retains for late joiners.";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 00/6:00:00";
      description = "How often to check the proxy for a renewed certificate.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The player server spawns `moq` to publish the encoder's output, so the CLI
    # has to be on a stable path. Installing it system-wide gives the app
    # /run/current-system/sw/bin/moq instead of a store path that moves on every
    # rebuild of the flake.
    environment.systemPackages = [ moq.moq ];

    # The relay's whole job is moving bulk UDP; the kernel's default socket
    # buffers clamp it and it logs a warning about exactly that.
    boot.kernel.sysctl."net.core.rmem_max" = lib.mkDefault 8388608;
    boot.kernel.sysctl."net.core.wmem_max" = lib.mkDefault 8388608;

    # QUIC (UDP) and the WebSocket fallback (TCP) share one port. It cannot be
    # 443: NPMplus already terminates 443/udp on the proxy host for HTTP/3, and
    # a reverse proxy cannot relay WebTransport at all — so on the WAN, 443/udp
    # belongs to the web ingress or to this relay, never both. VyOS therefore
    # forwards 8443 tcp+udp straight here, and RELAY_PUBLIC_URL carries the port
    # so the browser dials the relay directly.
    networking.firewall.allowedUDPPorts = [ 8443 ];
    networking.firewall.allowedTCPPorts = [ 8443 ];

    systemd.services.moq-cert-sync = {
      description = "Sync moq.orbsa.net's TLS certificate from the NPMplus proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = "users";
        ExecStart = "${certSync}/bin/moq-cert-sync";
      };
    };

    systemd.timers.moq-cert-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "15min";
      };
    };

    # Verifies the per-viewer tokens the player server mints. Without it the
    # relay has nobody to ask and refuses every session, which is the safe
    # direction to fail.
    systemd.services.moq-auth = {
      description = "MoQ relay auth server (verifies viewer JWTs)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = ''
          ${moq.moq}/bin/moq auth serve \
            --listen 127.0.0.1:4440 \
            --key ${cfg.keyDir}/public.jwk
        '';
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadOnlyPaths = [ cfg.keyDir ];
      };
    };

    systemd.services.moq-relay = {
      description = "Media over QUIC relay (Multiplex video feed)";
      after = [
        "network-online.target"
        "moq-cert-sync.service"
        "moq-auth.service"
      ];
      wants = [
        "network-online.target"
        "moq-auth.service"
      ];
      wantedBy = [ "multi-user.target" ];
      # A missing certificate is not a reason to refuse to start — the timer may
      # simply not have run yet on a fresh install — but the relay does need the
      # auth server up, or it would refuse every session it is asked about.
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = "${moq.moq-relay}/bin/moq-relay ${relayConfig}";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadOnlyPaths = [ cfg.tlsDir ];
      };
    };
  };
}
