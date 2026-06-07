{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ../modules/headless.nix
    ./plix-disko.nix
  ];
  # Override headless defaults
  time.timeZone = lib.mkForce "America/Chicago";
  system.stateVersion = lib.mkForce "24.11";

  # ── Boot ──────────────────────────────────────────────────────────
  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "nvme" ];
  boot.tmp.cleanOnBoot = true;

  # ── Filesystems (impermanence) ────────────────────────────────────
  # Root on tmpfs — wiped every boot.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  # Bind-mount /nix from /persist so the store survives reboots.
  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" ];
    depends = [ "/persist" ];
    neededForBoot = true;
  };

  # disko creates the /persist filesystem; mark it neededForBoot.
  fileSystems."/persist".neededForBoot = lib.mkForce true;

  # ── Networking ────────────────────────────────────────────────────
  networking.hostName = "plix";
  networking.useDHCP = false;
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "9.9.9.9" "1.1.1.1" ];
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "10.0.0.8";
    prefixLength = 23;
  }];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # ── Proxmox guest ─────────────────────────────────────────────────
  services.qemuGuest.enable = true;

  # ── NVIDIA Quadro P4000 (PCIe passthrough) ──────────────────────
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  hardware.nvidia = {
    open = false;                    # Pascal (GP104) — proprietary only
    modesetting.enable = true;
    powerManagement.enable = true;   # nvidia-persistenced for headless
    powerManagement.finegrained = false;
  };

  environment.systemPackages = with pkgs; [ nvtop ];

  # ── Users ─────────────────────────────────────────────────────────
  users.mutableUsers = true;
  users.users.root.initialPassword = "changeme";   # TODO

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" ];
    initialPassword = "changeme";                  # TODO
    openssh.authorizedKeys.keys = [
      # TODO: add your SSH public key
    ];
  };

  security.sudo.extraRules = [
    { users = [ "admin" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];

  # Service users for impermanence chown ordering.
  users.users.plex = {
    isSystemUser = true;
    group = "plex";
    extraGroups = [ "video" ];   # GPU access for HW transcoding
  };
  users.groups.plex = {};

  users.users.tautulli = {
    isSystemUser = true;
    group = "tautulli";
  };
  users.groups.tautulli = {};

  # ── SSH ───────────────────────────────────────────────────────────
  # openssh is enabled by headless; add stricter settings.
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };

  # Generate persistent host keys on first boot.
  system.activationScripts.sshHostKeys = {
    text = ''
      install -m 700 -d /persist/etc/ssh
      if [ ! -f /persist/etc/ssh/ssh_host_ed25519_key ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
          -f /persist/etc/ssh/ssh_host_ed25519_key -N "" \
          -C "root@${config.networking.hostName}"
        ${pkgs.openssh}/bin/ssh-keygen -t rsa \
          -f /persist/etc/ssh/ssh_host_rsa_key -N "" \
          -C "root@${config.networking.hostName}"
      fi
    '';
  };

  # ── NFS mounts — media library (10.0.0.10) ──────────────────────
  fileSystems."/data" = {
    device = "10.0.0.10:/mnt/user/Media";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "rsize=1048576"
      "wsize=1048576"
      "nconnect=4"
      "soft"
      "timeo=50"
      "retrans=3"
      "noatime"
      "actimeo=600"
      "x-systemd.requires=network-online.target"
      "x-systemd.mount-timeout=30s"
    ];
  };

  fileSystems."/data1" = {
    device = "10.0.0.10:/mnt/user/Media1";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "rsize=1048576"
      "wsize=1048576"
      "nconnect=4"
      "soft"
      "timeo=50"
      "retrans=3"
      "noatime"
      "actimeo=600"
      "x-systemd.requires=network-online.target"
      "x-systemd.mount-timeout=30s"
    ];
  };

  # ── Plex Media Server ─────────────────────────────────────────────
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  # ── Tautulli ──────────────────────────────────────────────────────
  services.tautulli = {
    enable = true;
    openFirewall = true;
  };

  # ── Impermanence: persistent paths ────────────────────────────────
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      {
        directory = "/var/lib/plexmediaserver";
        user = "plex";
        group = "plex";
        mode = "0755";
      }
      {
        directory = "/var/lib/plexpy";
        user = "tautulli";
        group = "tautulli";
        mode = "0700";
      }
      "/var/log"
      "/etc/nixos"
      { directory = "/home/admin"; user = "admin"; group = "users"; mode = "0700"; }
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # ── Kernel tweaks for 10G NFS throughput ─────────────────────────
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    "sunrpc.tcp_slot_table_entries" = 256;
  };

  # ── Auto-upgrade ──────────────────────────────────────────────────
  # Rebuilds from the flake in /persist/etc/nixos weekly.
  system.autoUpgrade = {
    enable = true;
    flake = "/persist/etc/nixos";
    flags = [ "--update-input" "nixpkgs" ];
    dates = "Mon *-*-* 03:00:00";
    randomizedDelaySec = "30min";
  };
}
