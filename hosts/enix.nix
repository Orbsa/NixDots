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
  };

  home-manager = {
    users = {
      "eric" = import ../home;
    };
  };
}
