{ config, lib, pkgs, ... }:

let
  cfg = config.my.homepage;
  pkg = pkgs.callPackage ../pkgs/homepage { };
in
{
  options.my.homepage = {
    enable = lib.mkEnableOption "homelab dashboard — network services homepage";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "TCP port the dashboard is served on";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.homepage = {
      description = "Homelab dashboard";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bun}/bin/bun ${pkg}/src/serve.ts";
        Environment = [ "BUN_PORT=${toString cfg.port}" ];
        WorkingDirectory = pkg;
        Restart = "on-failure";
        RestartSec = "5s";

        # Static, read-only workload — no state, no writes, no network except the
        # listen socket. Runs as an ephemeral user.
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictRealtime = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
      };
    };
  };
}
