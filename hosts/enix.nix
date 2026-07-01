{ inputs, lib, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./enix-hardware.nix
    ../modules/gaming.nix
    ../modules/runelite.nix
    ../modules/nvidia.nix
    ../modules/audio.nix
    inputs.nelko.nixosModules.default
    #../modules/virtualisation.nix
    #../modules/vfio.nix
  ];

  # Hardware-specific packages for this host
  environment.systemPackages = with pkgs; [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
    android-tools
    lm_sensors
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
    coolerdash
  ];

  # Set up CoolerDash plugin directory at runtime so CoolerControl discovers it.
  # Immutable files are symlinked from the nix store; config/credentials are
  # copied from defaults on first boot and preserved thereafter.
  systemd.tmpfiles.rules = let
    plug = "${pkgs.coolerdash}/share/coolerdash";
    dest = "/var/lib/coolercontrol/plugins/coolerdash";
  in [
    "d ${dest} 0755 root root -"
    "L+ ${dest}/manifest.toml  - - - - ${plug}/manifest.toml"
    "L+ ${dest}/ui            - - - - ${plug}/ui"
    "L+ ${dest}/shutdown.png  - - - - ${plug}/shutdown.png"
    "L+ ${dest}/coolerdash.png - - - - ${plug}/coolerdash.png"
    "L+ ${dest}/VERSION       - - - - ${plug}/VERSION"
    "L+ ${dest}/README.md     - - - - ${plug}/README.md"
    "L+ ${dest}/CHANGELOG.md  - - - - ${plug}/CHANGELOG.md"
    "C  ${dest}/config.json    0600 root root - ${plug}/config.json.default"
    "C  ${dest}/credentials.json 0600 root root - ${plug}/credentials.json.default"
  ];

  # CoolerControl can't manage plugin services on NixOS — it tries to
  # write unit files to /etc/systemd/system which is a read-only nix
  # store symlink. Disable its built-in service manager and define the
  # plugin unit ourselves.
  systemd.services.coolercontrold.serviceConfig.Environment =
    [ "CC_SERVICE_MANAGER=off" ];

  systemd.services.cc-plugin-coolerdash = {
    description = "CoolerControl Plugin coolerdash";
    after = [ "coolercontrold.service" ];
    requires = [ "coolercontrold.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.coolerdash}/bin/coolerdash";
      Restart = "on-failure";
      RestartSec = 30;
      TimeoutStopSec = 3;
    };
    unitConfig = {
      StartLimitIntervalSec = 60;
      StartLimitBurst = 10;
    };
  };

  services.nelko-pl70e = {
    enable = true;
    macAddress = "DC:0D:30:5A:A7:F5";
  };

  networking = {
    hostName = "enix";
    hostId = "6241ca71";
    interfaces.enp4s0 = {
      ipv4.addresses = [{
        address = "10.0.1.7";
        prefixLength = 23;
      }];
    };
    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp4s0";
    };
    nameservers = [ "10.0.0.1" "1.1.1.1"];
  };

  home-manager = { users = { "eric" = import ../home; }; };

  # ── Beszel Agent ──────────────────────────────────────────────────
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environment = {
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2l2VPJakeA9vf5Ljsab0iPAOJbSR7w3Ji4qYvllB+1";
      HUB_URL = "10.0.0.122";
      TOKEN = "295ff-63d2a565a-3fd09-0a35f3054";
    };
  };

  # Allow beszel-agent to access NVIDIA GPU devices
  systemd.services.beszel-agent.serviceConfig = {
    DeviceAllow = [
      "/dev/nvidiactl rw"
      "/dev/nvidia0 rw"
      "/dev/nvidia-modeset rw"
      "/dev/nvidia-uvm rw"
      "/dev/nvidia-uvm-tools rw"
    ];
    PrivateDevices = lib.mkForce false;
  };
}
