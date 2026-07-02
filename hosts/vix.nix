{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../modules/gandicloud.nix
    ../modules/headless.nix
    ../modules/tailscale.nix
    ../modules/smtp-relay.nix
    ../modules/beszel.nix
    ../modules/status-site.nix
    inputs.agenix.nixosModules.default
  ];

  networking.hostName = "vix";
  networking.domain = "thyrsos.tv";
  time.timeZone = "UTC";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      2143   # SSH
      80     # HTTP (ACME + nginx)
      443    # HTTPS
      587    # SMTP submission
      # 25 — SMTP inbound (opened by services.vix-mail when mode="backup")
    ];
  };

  # ── SSH ──────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    ports = [ 2143 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  services.fail2ban = {
    enable = true;
    jails.sshd.settings = {
      backend = "systemd";
      mode = "aggressive";
    };
  };

  # ── Users ────────────────────────────────────────────────────────
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos"
  ];

  users.users.eric = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  users.users.deploy = {
    isNormalUser = true;
    home = "/var/www/status";
    createHome = false;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos"
    ];
  };

  # ── ACME ─────────────────────────────────────────────────────────
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@thyrsos.tv";
  };

  # ── Swap ─────────────────────────────────────────────────────────
  swapDevices = [
    { device = "/swapfile"; size = 1536; }
  ];

  # ── Nix ──────────────────────────────────────────────────────────
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "Sat 03:00";
      options = "--delete-older-than 14d";
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos/vix";
    dates = "Sun 10:00";
    randomizedDelaySec = "30min";
    allowReboot = true;
    rebootWindow = { lower = "10:00"; upper = "11:30"; };
    flags = [ "--update-input" "nixpkgs" "-L" ];
  };

  # ── Packages ─────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    rsync
    tmux
    bun
    sqlite
    htop
    btop
  ];

  # ── Mail relay ───────────────────────────────────────────────────
  services.vix-mail.mode = "backup";
  # ── Beszel Agent ──────────────────────────────────────────────────
  my.beszel = {
    enable = true;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2l2VPJakeA9vf5Ljsab0iPAOJbSR7w3Ji4qYvllB+1";
  };

  # ── Status site ──────────────────────────────────────────────────
  age.secrets.plex-url.file = ../secrets/plex-url.age;
  age.secrets.maxmind-license-key.file = ../secrets/maxmind-license-key.age;

  services.vix-status-site = {
    enable = true;
    plexUrlFile = config.age.secrets.plex-url.path;
    maxmindLicenseKeyFile = config.age.secrets.maxmind-license-key.path;
  };
  system.stateVersion = "24.11";
}
