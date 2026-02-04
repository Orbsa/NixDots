{ config, lib, pkgs, ... }:

{
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd = {
      enable = true;
      extraConfig = ''
        user="eric"
      '';
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        verbatimConfig = ''
           namespaces = []
          user = "+${builtins.toString config.users.users.eric.uid}"
        '';
      };
    };
  };

  systemd = {
    tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 eric qemu-libvirtd -"
      "f /dev/shm/scream 0660 eric qemu-libvirtd -"
      "L /var/lib/libvirt/qemu - - - - /persist/var/lib/libvirt/qemu"
      "L /var/lib/flatpak - - - - /persist/var/lib/flatpak "
    ];

    user.services.scream-ivshmem = {
      enable = true;
      description = "Scream IVSHMEM";
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream-ivshmem-pulse /dev/shm/scream";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "pipewire-pulse.service" ];
    };
  };

  environment.systemPackages = with pkgs; [
    looking-glass-client
    scream
    virt-manager
  ];
}
