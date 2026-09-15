{ config, lib, pkgs, inputs, ... }:

{
  _module.args.username = "eric";

  imports = [ ./common.nix ./thinix-hardware.nix ../modules/headless.nix ];

  networking = {
    hostName = "thinix";
    hostId = "6241ca71";
  };

  home-manager = { users = { "eric" = import ../home; }; };
}
