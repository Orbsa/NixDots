{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.agenix.nixosModules.default
    ../modules/headless.nix
    ../modules/tailscale.nix
    ../modules/beszel.nix
    ./plix-disko.nix
    ../modules/k3s.nix
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
    address = "10.0.0.7";
    prefixLength = 23;
  }];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 9443 8131 2022 ];   # 9443=Portainer, 8131=Wings API, 2022=Wings SFTP
    # Game server allocations (Wings hostNetwork)
    allowedTCPPortRanges = [ { from = 25565; to = 25575; } ];
  };

  # ── Proxmox guest ─────────────────────────────────────────────────
  services.qemuGuest.enable = true;

  # ── NVIDIA Quadro P4000 (PCIe passthrough) ──────────────────────
  hardware.graphics.enable = true;

  # The nvidia module enables itself only when "nvidia" is in
  # services.xserver.videoDrivers — even for headless servers.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;                    # Pascal (GP104) — proprietary only
    modesetting.enable = true;
    powerManagement.enable = true;   # nvidia-persistenced for headless
    powerManagement.finegrained = false;
  };

  environment.systemPackages = with pkgs; [ nvitop ];
  # ── Secrets (agenix) ────────────────────────────────────────────
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.admin-password = {
    file = ../secrets/admin-password.age;
  };

  # ── Users ─────────────────────────────────────────────────────────
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";   # locked — admin has sudo NOPASSWD

  users.users.admin = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "video" "docker" ];
    hashedPasswordFile = config.age.secrets.admin-password.path;
    openssh.authorizedKeys.keys = [
      # TODO: add your SSH public key
    ];
  };

  security.sudo.extraRules = [
    { users = [ "admin" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];

  # Service users — declared so impermanence creates persistent dirs
  # with correct ownership before services start.
  users.users.plex = {
    isSystemUser = true;
    group = "plex";
    extraGroups = [ "video" ];
  };
  users.groups.plex = {};

  # Note: services.tautulli creates its own plexpy user; the tautulli
  # user below was unused and is replaced by the module's plexpy user.
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
  # ── Beszel Agent ──────────────────────────────────────────────────
  my.beszel = {
    enable = true;
    enableGpu = true;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2l2VPJakeA9vf5Ljsab0iPAOJbSR7w3Ji4qYvllB+1";
  };

  # ── k3s Kubernetes (game servers) ─────────────────────────────────
  my.k3s = {
    enable = true;
    enableGpu = true;  # NVIDIA Quadro P4000 — nvidia.com/gpu resources for pods
  };

  # ── Docker (for Wings + Portainer) ─────────────────────────────────
  virtualisation.docker.enable = true;

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

  # Cap Plex's page cache at 64G via cgroup memory.high (soft limit).
  # Plex has read 1.6TB from NFS and without limits Linux caches every
  # byte — 380G+ on a 393G box. Actual process RSS is <1G; this just
  # bounds the file cache so there's room for the transcode tmpfs.
  systemd.services.plex.serviceConfig.MemoryHigh = "64G";

  # ── Plex transcode tmpfs (ramdisk) ───────────────────────────────
  # Sized for 40 streams × 100 Mbps × 60s buffer + 150% overhead ≈ 73G.
  # 96G gives comfortable headroom. tmpfs only uses RAM for stored files
  # — the quota is a cap, not a reservation. Empty dir costs nothing.
  fileSystems."/var/lib/plex-transcode" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=96G"
      "mode=1777"
      "noatime"
    ];
  };

  # Ensure the transcode dir exists with correct ownership.
  systemd.tmpfiles.rules = [
    "d /var/lib/plex-transcode 1777 plex plex - -"
  ];

  # Plex can write to /var/lib/plex-transcode because ProtectSystem=true
  # only makes /usr, /boot, /etc read-only — /var remains writable.

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
        directory = "/var/lib/plex";
        user = "plex";
        group = "plex";
        mode = "0755";
      }
      {
        directory = "/var/lib/plexpy";
        user = "plexpy";
        group = "nogroup";
        mode = "0700";
      }
      { directory = "/var/lib/nixos"; mode = "0755"; }
      "/var/lib/tailscale"
      "/var/log"
      "/etc/nixos"
      "/var/cache/plocate"
      "/var/lib/docker"
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
