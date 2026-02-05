{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ./enix-hardware.nix
    ../modules/gaming.nix
    ../modules/nvidia.nix
    ../modules/audio.nix
    #../modules/virtualisation.nix
    #../modules/vfio.nix
  ];

  networking = {
    hostName = "enix";
    hostId = "6241ca71";
    interfaces.enp4s0 = {
      ipv4.addresses = [{
        address = "172.16.1.127";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "172.16.1.1";
      interface = "enp4s0";
    };
    nameservers = [ "9.9.9.9" "1.1.1.1" ];
  };

  home-manager = { users = { "eric" = import ../home; }; };
}
