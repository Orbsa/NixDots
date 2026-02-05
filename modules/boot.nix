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

  environment.systemPackages = [ pkgs.sbctl ];
}
