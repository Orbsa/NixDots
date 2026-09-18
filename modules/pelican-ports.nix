{ config, lib, pkgs, ... }:

let
  cfg = config.my.pelicanPorts;

  script = pkgs.writeShellApplication {
    name = "pelican-port-sync";
    runtimeInputs = with pkgs; [
      k3s
      kubectl
      iptables
      openssh
      coreutils
      gawk
      gnugrep
      gnused
    ];
    text = builtins.readFile ./pelican-port-sync.sh;
  };
in
{
  options.my.pelicanPorts = {
    enable = lib.mkEnableOption "auto-sync Pelican game-server ports to firewall + VyOS NAT";

    nodeId = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Pelican node id (this host) whose allocations are synced.";
    };

    namespace = lib.mkOption {
      type = lib.types.str;
      default = "pelican";
      description = "k8s namespace of the Pelican stack.";
    };

    mysqlDeploy = lib.mkOption {
      type = lib.types.str;
      default = "pelican-mysql";
      description = "k8s deployment name of the panel MySQL.";
    };

    iptablesChain = lib.mkOption {
      type = lib.types.str;
      default = "PELICAN-PORTS";
      description = "iptables chain populated with game-port ACCEPT rules.";
    };

    syncInterval = lib.mkOption {
      type = lib.types.str;
      default = "2min";
      description = "systemd OnUnitActiveSec for the sync timer.";
    };

    vyos = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Push DST-NAT rules to VyOS over SSH.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "10.0.0.1";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "vyos";
      };
      identityFile = lib.mkOption {
        type = lib.types.str;
        default = "/persist/pelican/vyos/ssh_key";
        description = "Path to a passphrase-less SSH key authorized on VyOS.";
      };
      wanInterface = lib.mkOption {
        type = lib.types.str;
        default = "eth1";
        description = "VyOS inbound (WAN) interface for the DST-NAT rules.";
      };
      targetAddress = lib.mkOption {
        type = lib.types.str;
        default = "10.0.0.7";
        description = "LAN address to forward game traffic to (this host).";
      };
      natRuleNumber = lib.mkOption {
        type = lib.types.int;
        default = 400;
        description = "VyOS nat-destination rule number used by this sync (grouped).";
      };
      firewallRuleNumber = lib.mkOption {
        type = lib.types.int;
        default = 400;
        description = "VyOS WAN_IN firewall rule number used by this sync (grouped).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the dynamic chain exists and is jumped from nixos-fw *before*
    # the final refuse rule, on every firewall (re)build.
    networking.firewall.extraCommands = lib.mkAfter ''
      ${pkgs.iptables}/bin/iptables -N ${cfg.iptablesChain} 2>/dev/null \
        || ${pkgs.iptables}/bin/iptables -F ${cfg.iptablesChain}
      ${pkgs.iptables}/bin/iptables -C nixos-fw -j ${cfg.iptablesChain} 2>/dev/null \
        || ${pkgs.iptables}/bin/iptables -I nixos-fw 1 -j ${cfg.iptablesChain}
      # Best-effort immediate populate (no-op if k3s/mysql isn't up yet at boot).
      ${script}/bin/pelican-port-sync firewall-only || true
    '';

    systemd.services.pelican-port-sync = {
      description = "Sync Pelican game ports to firewall and VyOS NAT";
      wantedBy = [ "multi-user.target" ];
      after = [ "k3s.service" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}/bin/pelican-port-sync";
        Environment = [
          "NODE_ID=${toString cfg.nodeId}"
          "NAMESPACE=${cfg.namespace}"
          "MYSQL_DEPLOY=${cfg.mysqlDeploy}"
          "IPT_CHAIN=${cfg.iptablesChain}"
          "VYOS_ENABLE=${if cfg.vyos.enable then "1" else "0"}"
          "VYOS_HOST=${cfg.vyos.host}"
          "VYOS_USER=${cfg.vyos.user}"
          "VYOS_KEY=${cfg.vyos.identityFile}"
          "VYOS_WAN_IF=${cfg.vyos.wanInterface}"
          "VYOS_TARGET=${cfg.vyos.targetAddress}"
          "VYOS_NAT_RULE=${toString cfg.vyos.natRuleNumber}"
          "VYOS_FW_RULE=${toString cfg.vyos.firewallRuleNumber}"
        ];
      };
    };

    systemd.timers.pelican-port-sync = {
      description = "Periodically reconcile Pelican ports";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.syncInterval;
        AccuracySec = "10s";
        Persistent = true;
      };
    };
  };
}
