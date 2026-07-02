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
  };

  config = lib.mkIf cfg.enable {
    age.secrets.beszel-token.file = ../secrets/beszel-token.age;

    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      environment = {
        KEY = cfg.key;
        HUB_URL = cfg.hubUrl;
      };
    };

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
