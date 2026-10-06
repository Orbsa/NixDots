{ config, lib, pkgs, inputs, ... }:

let
  # `llm-agents`' hermes-agent is a Python application whose runtime sys.path is
  # assembled inside its own launcher (`site.addsitedir` over ~160 store dirs).
  # The package exposes no python env and no `passthru.hermesVenv`, so the
  # WebUI's in-process agent runtime gets a shim that reproduces that sys.path.
  hermesAgent = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hermes-agent;
  pyVerRe = lib.replaceStrings [ "." ] [ "\\." ] pkgs.python3.pythonVersion;
  hermesAgentPython = pkgs.writeShellScriptBin "hermes-agent-python" ''
    launch=${hermesAgent}/bin/.hermes-wrapped
    py=$(${pkgs.gnused}/bin/sed -n '1s|^#!||p' "$launch")
    dirs=$(${pkgs.gnugrep}/bin/grep -oE "/nix/store/[^']+/lib/python${pyVerRe}/site-packages" "$launch" \
      | ${pkgs.coreutils}/bin/sort -u | ${pkgs.coreutils}/bin/paste -sd: -)
    export PYTHONPATH="$dirs''${PYTHONPATH:+:$PYTHONPATH}"
    exec "$py" "$@"
  '';
in
{
  imports = [
    inputs.hermes-webui.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.agenix.nixosModules.default
    ../modules/headless.nix
    ../modules/tailscale.nix
    ../modules/beszel.nix
    ../modules/homepage.nix
    ./plix-disko.nix
    ../modules/k3s.nix
    ../modules/pelican-ports.nix
  ];
  # Override headless defaults
  time.timeZone = lib.mkForce "America/Chicago";
  system.stateVersion = lib.mkForce "24.11";

  # ── Boot ──────────────────────────────────────────────────────────
  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # The 512M ESP had filled to 100% (65 generations, unlimited entries), so
  # bootloader install failed with ENOSPC. systemd-boot's installer
  # garbage-collects before writing, so capping the generations copied to
  # /boot lets it reclaim the space first. Raise once the ESP is resized.
  boot.loader.systemd-boot.configurationLimit = 5;
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
  # VyOS (10.0.0.1) is the LAN resolver: authoritative for orbsa.net etc.
  # and forwards everything else. Must NOT use public DNS here — that
  # resolves orbsa.net to the public IP (75.169.239.102) which has no
  # port-forwards, so the Pelican panel pod can't reach Wings by name
  # (k3s CoreDNS forwards to /etc/resolv.conf).
  networking.nameservers = [ "10.0.0.1" ];
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "10.0.0.7";
    prefixLength = 23;
  }];
  networking.extraHosts = ''
    10.0.0.3 wings.game.orbsa.net
    10.0.0.3 wings.games.orbsa.net
    10.0.0.3 game.orbsa.net
    10.0.0.3 home.orbsa.net
  '';

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 9443 8131 2022 8211 ];   # 9443=Portainer, 8131=Wings API, 2022=Wings SFTP
    # Game server allocations (Wings hostNetwork)
    allowedTCPPortRanges = [ { from = 25565; to = 25575; } ];
    allowedUDPPorts = [ 16261 16262 ];              # Project Zomboid (VyOS DST-NAT-55/56)
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

  environment.systemPackages = with pkgs; [
    nvitop
    # Coding agent — plix is the machine with pi, enix keeps omp.
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
    # JS toolchain — npm ships with nodejs; bun is what pi's agent tooling
    # and local package builds expect.
    bun
    nodejs
    # LLM CLI proxy — reduces token consumption on common dev commands.
    rtk
  ];
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
    # Start the user manager at boot with nobody logged in. The Costco
    # shift-sync bot is a --user service, and /var is tmpfs here (impermanence),
    # so this flag cannot be set imperatively — leave it to the flake, or the
    # weekly Mon 22:00 run silently never fires after a reboot.
    linger = true;
    extraGroups = [ "wheel" "video" "docker" ];
    shell = pkgs.fish;
    hashedPasswordFile = config.age.secrets.admin-password.path;
    openssh.authorizedKeys.keys = [
      # eric@Stratos — the key vix/enix already trust.
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos"
    ];
  };

  security.sudo.extraRules = [
    { users = [ "admin" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];

  # ── Home Manager — neovim/tmux terminal environment (as on enix) ──
  # home/headless.nix pulls in fish, starship, atuin, neovim and tmux.
  home-manager = {
    users.admin = {
      imports = [ ../home/headless.nix ];
      home.stateVersion = "24.11";
      # Standalone in-memory ssh-agent. headless.nix defaults to gpg-agent's
      # ssh emulation, but its pinentry has no controlling TTY on this
      # headless host, so `ssh-add` fails with "agent refused operation".
      services.gpg-agent.enableSshSupport = lib.mkForce false;
      services.ssh-agent.enable = lib.mkForce true;
    };
  };

  # Service users — declared so impermanence creates persistent dirs
  # with correct ownership before services start.
  users.users.plex = {
    isSystemUser = true;
    group = "plex";
    extraGroups = [ "video" ];
  };
  users.groups.plex = {};

  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
    extraGroups = [ "video" "render" ];
  };
  users.groups.jellyfin = {};

  # Note: services.tautulli creates its own plexpy user; the tautulli
  # user below was unused and is replaced by the module's plexpy user.
  # ── SSH ───────────────────────────────────────────────────────────
  # openssh is enabled by headless; add stricter settings.
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  # Generate persistent host keys on first boot.
  system.activationScripts.sshHostKeys = {
    text = ''
      install -m 755 -d /persist/etc/ssh
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

  # ── Homelab dashboard (network services homepage) ──────────────────
  my.homepage = {
    enable = true;
    port = 8787;
  };

  # ── k3s Kubernetes (game servers) ─────────────────────────────────
  my.k3s = {
    enable = true;
    enableGpu = true;  # NVIDIA Quadro P4000 — nvidia.com/gpu resources for pods
    # VyOS (10.0.0.1) is the LAN resolver: authoritative for orbsa.net etc.
    # CoreDNS forwards to it so pods resolve local records without hostAliases.
    dnsUpstream = "10.0.0.1";
  };

  # ── Pelican game-port auto-sync (host firewall + VyOS NAT) ───────
  # Reads this node's allocations from the panel DB and, on a 2min timer,
  # opens every allocated port (TCP+UDP) in the host firewall and pushes
  # matching DST-NAT rules to VyOS. See ../modules/pelican-ports.nix.
  my.pelicanPorts = {
    enable = true;
    nodeId = 7;
    vyos = {
      enable = true;
      wanInterface = "eth1";   # VyOS WAN interface (75.169.239.102)
    };
  };

  # ── Docker (for Wings + Portainer) ─────────────────────────────────
  virtualisation.docker.enable = true;

  # Bind-mount Wings /etc/pelican to persistent storage
  fileSystems."/etc/pelican" = {
    device = "/persist/pelican/wings/etc";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/tmp/pelican" = {
    device = "/persist/pelican/wings/tmp";
    fsType = "none";
    options = [ "bind" ];
  };

  # ── CIFS mounts — media library (10.0.0.10) ──────────────────────
  # Was NFS, but Unraid 7.3.1 FUSE/shfs readdir is broken over NFS re-export.
  # CIFS works correctly through the shfs layer.
  fileSystems."/data" = {
    device = "//10.0.0.10/Media";
    fsType = "cifs";
    options = [
      "guest"
      "vers=3.0"
      "uid=193"
      "gid=100"
      "forceuid"
      "forcegid"
      "file_mode=0755"
      "dir_mode=0755"
      "rsize=4194304"
      "wsize=4194304"
      "cache=strict"
      "noatime"
      "nofail"
      "x-systemd.requires=network-online.target"
    ];
  };

  fileSystems."/data1" = {
    device = "//10.0.0.10/Media1";
    fsType = "cifs";
    options = [
      "guest"
      "vers=3.0"
      "uid=193"
      "gid=100"
      "forceuid"
      "forcegid"
      "file_mode=0755"
      "dir_mode=0755"
      "rsize=4194304"
      "wsize=4194304"
      "cache=strict"
      "noatime"
      "nofail"
      "x-systemd.requires=network-online.target"
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

  # ── Jellyfin transcode tmpfs (ramdisk) ─────────────────────────────
  # Smaller than Plex — Jellyfin has fewer concurrent streams.
  # 16G covers ~8 streams × 100 Mbps × 60s buffer + overhead.
  fileSystems."/var/lib/jellyfin/transcodes" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=16G"
      "mode=1777"
      "noatime"
    ];
  };

  # Ensure transcode dirs exist with correct ownership.
  systemd.tmpfiles.rules = [
    "d /var/lib/plex-transcode 1777 plex plex - -"
    "d /var/lib/jellyfin/transcodes 1777 jellyfin jellyfin - -"
  ];

  # Plex can write to /var/lib/plex-transcode because ProtectSystem=true
  # only makes /usr, /boot, /etc read-only — /var remains writable.

  # ── Tautulli ──────────────────────────────────────────────────────
  services.tautulli = {
    enable = true;
    openFirewall = true;
  };

  # ── Jellyfin Media Server ──────────────────────────────────────────
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    hardwareAcceleration = {
      enable = true;
      type = "nvenc";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = true;
    transcoding = {
      enableToneMapping = true;
      enableSubtitleExtraction = true;
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        mpeg2 = true;
        vc1 = true;
        vp8 = true;
        vp9 = true;
      };
    };
  };

  # Jellyfin's preStart writes encoding.xml before tmpfiles creates
  # the config dir — on ephemeral root the directory chain is missing.
  systemd.services.jellyfin = {
    preStart = lib.mkBefore ''
      mkdir -p /var/lib/jellyfin/config
    '';
    after = [ "systemd-tmpfiles-setup.service" ];
    wants = [ "systemd-tmpfiles-setup.service" ];
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
      {
        directory = "/var/lib/jellyfin";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0700";
      }
      {
        directory = "/var/cache/jellyfin";
        user = "jellyfin";
        group = "jellyfin";
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

  # ── Git trust for root-run rebuilds ───────────────────────────────
  # `nixos-rebuild` and system.autoUpgrade run as root, and
  # `--flake /home/admin/nix` resolves to `git+file://`. libgit2 refuses a
  # repo owned by another user, so root rebuilds died with "repository path
  # '/home/admin/nix' is not owned by current user" — which is why this host's
  # weekly autoUpgrade had been failing silently on every run. Declared rather
  # than set imperatively: /etc/gitconfig is regenerated from the closure on
  # each boot, while `git config --global` would land in /root (tmpfs) and be
  # wiped.
  programs.git = {
    # `enable` is required: the module only writes /etc/gitconfig under
    # `mkIf cfg.enable`, so setting `config` alone silently emits no file and
    # the rebuild comes out byte-identical to the previous one.
    enable = true;
    config = {
      safe = { directory = "/home/admin/nix"; };
    };
  };

  # ── Auto-upgrade ──────────────────────────────────────────────────
  # Rebuilds from /home/admin/nix weekly (avoids git+file:// clone edge cases).
  system.autoUpgrade = {
    enable = true;
    flake = "/home/admin/nix";
    flags = [ "--update-input" "nixpkgs" ];
    dates = "Mon *-*-* 03:00:00";
    randomizedDelaySec = "30min";
  };

  # ── Hermes WebUI (browser front-end for the Hermes Agent) ──────────
  # Declarative service from github:nesquena/hermes-webui, pinned in
  # flake.nix. Tailnet-only: it binds plix's Tailscale address and the
  # firewall admits the port on tailscale0 only (not LAN/WAN). 8787 is
  # taken by the homelab homepage.
  #
  # Runs as `admin` because the WebUI reads HERMES_HOME directly and
  # ~/.hermes is mode 0700, and because the Chat runs the Hermes agent
  # in-process — hence the `hermesAgentPython` shim above.
  services.hermes-webui = {
    enable = true;
    # Bound on all interfaces so NPMplus on `proxy` (10.0.0.3) can reach it over
    # the LAN; the firewall below admits only the tailnet and that one source.
    host = "0.0.0.0";
    port = 8788;
    user = "admin";
    group = "users";
    hermesHome = "/home/admin/.hermes";
    stateDir = "/home/admin/.hermes/webui";
    agent = {
      dir = "${hermesAgent}/${pkgs.python3.sitePackages}";
      python = "${hermesAgentPython}/bin/hermes-agent-python";
    };
    extraEnvironment = {
      HOME = "/home/admin";
      PATH = "${hermesAgent}/bin:/run/current-system/sw/bin:/run/wrappers/bin:/home/admin/.nix-profile/bin";
    };
  };
  # Tailnet peers may hit the UI directly; NPMplus reaches it over the LAN from
  # exactly one source. Nothing else on the LAN (or the WAN) can open the port.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8788 ];
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 10.0.0.3/32 --dport 8788 -j nixos-fw-accept
  '';
  systemd.services.hermes-webui = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
  };

  # ── Hermes Agent gateway ──────────────────────────────────────────
  # The daemon the WebUI's scheduled jobs need for their cron ticks
  # ("Gateway not configured" banner). It writes
  # ~/.hermes/gateway_state.json, which is what the WebUI polls. No
  # messaging platform is configured, so it only drives schedules.
  #
  # Declared here rather than via `hermes gateway install --system`
  # because plix's root is tmpfs — an imperatively written unit would not
  # survive a reboot.
  systemd.services.hermes-gateway = {
    description = "Hermes Agent gateway daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      HOME = "/home/admin";
      HERMES_HOME = "/home/admin/.hermes";
      # Kanban workers are spawned as detached children. Without this the
      # dispatcher builds the worker argv as `<sys.executable> -m
      # hermes_cli.main`, but llm-agents' hermes-agent injects its sys.path via
      # `site.addsitedir` inside the wrapper rather than PYTHONPATH, so the
      # child dies with "No module named 'hermes_cli'" and the task auto-blocks.
      # HERMES_BIN makes _resolve_hermes_argv() use the wrapped launcher.
      HERMES_BIN = "${hermesAgent}/bin/hermes";
      # mkForce: systemd.nix defines a default PATH for every unit.
      PATH = lib.mkForce "${hermesAgent}/bin:/run/current-system/sw/bin:/run/wrappers/bin:/home/admin/.nix-profile/bin";
    };
    serviceConfig = {
      Type = "simple";
      User = "admin";
      Group = "users";
      ExecStart = "${hermesAgent}/bin/hermes gateway run";
      Restart = "on-failure";
      RestartSec = 10;
      UMask = "0077";
    };
  };
}
