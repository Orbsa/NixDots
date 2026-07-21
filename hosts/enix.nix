{ inputs, pkgs, config, lib, ... }:

{
  _module.args.username = "eric";

  imports = [
    ./common.nix
    ./enix-hardware.nix
    ../modules/gaming.nix
    ../modules/runelite.nix
    ../modules/nvidia.nix
    inputs.nelko.nixosModules.default
    ../modules/headless.nix
    ../modules/beszel.nix
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
  ];


  # Persist critical runtime state across ZFS rollback
  systemd.tmpfiles.rules = [
    "d /persist/var/lib/tailscale 0755 root root -"
    "L /var/lib/tailscale - - - - /persist/var/lib/tailscale"
  ];

  # systemd StateDirectory=tailscale chokes on the symlink above
  systemd.services.tailscaled.serviceConfig.StateDirectory = lib.mkForce "";

  # CoolerControl tries to manage plugin services by writing unit files to
  # /etc/systemd/system (read-only on NixOS). Disable its service manager.
  systemd.services.coolercontrold.serviceConfig.Environment =
    [ "CC_SERVICE_MANAGER=off" ];
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

  # ── Secrets (agenix) ────────────────────────────────────────────
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  # Generate persistent SSH host keys on first boot so agenix can
  # decrypt secrets after ZFS rollback.
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
      for key in ssh_host_ed25519_key ssh_host_rsa_key; do
        for ext in "" ".pub"; do
          t=/etc/ssh/$key$ext
          s=/persist/etc/ssh/$key$ext
          if [ ! -L "$t" ] || [ "$(readlink "$t")" != "$s" ]; then
            rm -f "$t"
            ln -s "$s" "$t"
          fi
        done
      done
    '';
  };

  # Persist machine-id so license activations (Bitwig, etc.) survive
  # ZFS rollback. Systemd reads this before activation runs, so the
  # symlink only takes effect on the next boot after the @blank
  # snapshot is updated.
  system.activationScripts.machineId = {
    text = ''
      if [ ! -f /persist/etc/machine-id ]; then
        cp /etc/machine-id /persist/etc/machine-id
      fi
      if [ ! -L /etc/machine-id ] || [ "$(readlink /etc/machine-id)" != /persist/etc/machine-id ]; then
        rm -f /etc/machine-id
        ln -s /persist/etc/machine-id /etc/machine-id
      fi
    '';
  };

  home-manager = { users = { "eric" = import ../home; }; };
  # ── Beszel Agent ──────────────────────────────────────────────────
  my.beszel = {
    enable = true;
    enableGpu = true;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2l2VPJakeA9vf5Ljsab0iPAOJbSR7w3Ji4qYvllB+1";
  };
}
