{ config, lib, pkgs, ... }:

{
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = false; # Disabled because using Lanzaboote
        zfsSupport = true;
        efiSupport = true;
        mirroredBoots = [{
          devices = [ "nodev" ];
          path = "/boot";
        }];
      };
      systemd-boot.enable = lib.mkForce false;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;
    };
  };

  systemd.tmpfiles.rules = [
    "L /var/lib/sbctl    - - - - /persist/var/lib/sbctl"
    "d /persist/var/log/journal 2755 root systemd-journal -"
    "L /var/log/journal  - - - - /persist/var/log/journal"
  ];

  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxFiles=10
    SystemMaxUse=500M
    MaxFileSec=1week
  '';

  systemd.settings.Manager.DefaultTimeoutStopSec = "15s";

  environment.systemPackages = [ pkgs.sbctl ];
}
