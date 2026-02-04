{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ./thinix-hardware.nix
  ];

  networking = {
    hostName = "thinix";
    hostId = "6241ca71";
  };

  home-manager = {
    users = {
      "eric" = import ../home;
    };
  };
}
