{ config, lib, ... }:
let
  cfg = config.my.beszel;
in
{
  options.my.beszel = {
    enable = lib.mkEnableOption "Beszel monitoring agent";
    enableGpu = lib.mkEnableOption "NVIDIA GPU monitoring access for beszel-agent";
    key = lib.mkOption {
      type = lib.types.str;
      description = "SSH public key for beszel hub authentication";
    };
    hubUrl = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.122";
      description = "Beszel hub URL";
    };
    allowedFrom = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.0.0.122" "100.83.96.103" ];
      description = ''
        Source addresses allowed to reach the agent port (45876). Only the hub
        connects in: its macvlan address on the LAN, and its own tailnet node
        identity for remote agents such as vix.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.beszel-token.file = ../secrets/beszel-token.age;

    services.beszel.agent = {
      enable = true;
      # Was `true`, which opened 45876 to every network (LAN and tailnet). Only
      # the hub ever connects in, so it is scoped to cfg.allowedFrom below.
      openFirewall = false;
      environment = {
        KEY = cfg.key;
        HUB_URL = cfg.hubUrl;
      };
    };

    # `openFirewall = false` above means nothing opens 45876 automatically.
    # Measured sources: the hub reaches LAN agents from its macvlan address
    # 10.0.0.122, and remote agents (vix) over the tailnet from its own node
    # identity 100.83.96.103 (tailnet name `beszel`, a container on unraid).
    networking.firewall.extraInputRules = ''
      ip saddr { ${lib.concatStringsSep ", " cfg.allowedFrom} } tcp dport 45876 accept
    '';

    # Token via agenix — copied via LoadCredential so the dynamic user can read it.
    # RuntimeDirectory gives the service user a writeable dir under /run.
    systemd.services.beszel-agent = {
      preStart = ''
        printf 'TOKEN=%s\n' "$(cat $CREDENTIALS_DIRECTORY/beszel-token)" > /run/beszel-agent/token.env
      '';
      serviceConfig = {
        RuntimeDirectory = "beszel-agent";
        LoadCredential = "beszel-token:${config.age.secrets.beszel-token.path}";
        EnvironmentFile = lib.mkForce "-/run/beszel-agent/token.env";
      } // lib.optionalAttrs cfg.enableGpu {
        PrivateDevices = lib.mkForce false;
        SupplementaryGroups = lib.mkAfter [ "video" ];
        DeviceAllow = [
          "/dev/nvidiactl rw"
          "/dev/nvidia0 rw"
          "/dev/nvidia-modeset rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
        ];
      };
    };
  };
}
