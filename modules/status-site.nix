{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.services.vix-status-site;
  domain = "status.thyrsos.tv";
  appDir = "/var/www/status/app";
in {
  options.services.vix-status-site = {
    enable = lib.mkEnableOption "status.thyrsos.tv — uptime page";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../pkgs/vix-status-site.nix {
        src = inputs.vix-status-site;
      };
      description = "The status-site package to deploy";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the Bun server listens on";
    };

    plexUrlFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to agenix-decrypted file containing PLEX_URL=...";
    };

    maxmindLicenseKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to agenix-decrypted MaxMind license key. DB is downloaded at service start.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── User ────────────────────────────────────────────────────────
    users.users.status-site = {
      isSystemUser = true;
      group = "status-site";
      home = appDir;
      createHome = false;
    };
    users.groups.status-site = {};

    systemd.tmpfiles.rules = [
      "d /var/www         0755 root        root          - -"
      "d /var/www/status  0755 root        root          - -"
      "d ${appDir}        0755 status-site status-site   - -"
    ];

    # ── Service ─────────────────────────────────────────────────────
    systemd.services.status-site = {
      description = "status.thyrsos.tv — uptime page";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.iputils pkgs.bun pkgs.curl pkgs.gnutar pkgs.gzip ];
      preStart = ''
      '' + lib.optionalString (cfg.maxmindLicenseKeyFile != null) ''
        # ── GeoLite2 database ──────────────────────────────────────
        DB="%S/status-site/GeoLite2-City.mmdb"
        if [ ! -f "$DB" ] || [ "$(find "$DB" -mtime +7 2>/dev/null)" ]; then
          echo "Downloading GeoLite2-City database…"
          if curl -sSfL "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$(cat $CREDENTIALS_DIRECTORY/maxmind-license-key)&suffix=tar.gz" \
            | tar -xz --strip-components=1 -C "%S/status-site" --wildcards '*.mmdb'; then
            echo "GeoLite2 database updated."
          else
            echo "WARNING: GeoLite2 download failed — geo-IP lookups will be unavailable"
          fi
        fi
      '' + ''
        set -e
        # ── App source ─────────────────────────────────────────────
        if ! cmp -s "${cfg.package}/package.json" "${appDir}/package.json" 2>/dev/null; then
          chmod -R u+w "${appDir}" 2>/dev/null || true
          rm -rf "${appDir}"/*
          cp -r "${cfg.package}"/* "${appDir}/"
          chown -R status-site:status-site "${appDir}"
        fi
        # Install deps if needed
        cd "${appDir}"
        if [ ! -d node_modules ]; then
          bun install --frozen-lockfile --production --no-progress
        fi
      '';


      serviceConfig = {
        ExecStartPre = lib.mkBefore [
          "+${pkgs.coreutils}/bin/chown -R status-site:status-site ${appDir}"
        ];
        Type = "simple";
        User = "status-site";
        Group = "status-site";
        WorkingDirectory = appDir;
        LoadCredential = lib.mkIf (cfg.maxmindLicenseKeyFile != null) [
          "maxmind-license-key:${cfg.maxmindLicenseKeyFile}"
        ];
        EnvironmentFile = lib.mkIf (cfg.plexUrlFile != null) cfg.plexUrlFile;
        Environment = lib.mkMerge [
          [
            "PORT=${toString cfg.port}"
            "BUN_INSTALL=/var/lib/status-site/.bun"
            "DB_PATH=/var/lib/status-site/data.db"
          ]
          (lib.mkIf (cfg.maxmindLicenseKeyFile != null) [
            "MAXMIND_DB_PATH=/var/lib/status-site/GeoLite2-City.mmdb"
          ])
        ];
        ExecStart = "${pkgs.bun}/bin/bun run ${appDir}/src/server.ts";
        Restart = "on-failure";
        RestartSec = "5s";

        StateDirectory = "status-site";
        StateDirectoryMode = "0750";

        AmbientCapabilities = [ "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_RAW" ];

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/status-site" appDir ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = false;
      };
    };

    # ── Nginx ───────────────────────────────────────────────────────
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        serverAliases = [ "status.orbsa.net" ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          proxyWebsockets = true;
        };
      };
    };

    security.acme.certs.${domain}.extraDomainNames = [ "status.orbsa.net" ];
  };
}
