{ config, lib, pkgs, inputs, ... }:

# DEPRECATED host. No password hash is declared for it any more (modules/users.nix
# no longer carries cleartext hashes), so eric/root are key-only here: SSH with
# eric@Stratos's key still works, local console password login does not.
# Remove this host from flake.nix when it is finally retired.
{
  _module.args.username = "eric";

  imports = [ ./common.nix ./thinix-hardware.nix ../modules/headless.nix ];

  networking = {
    hostName = "thinix";
    hostId = "6241ca71";
  };

  home-manager = { users = { "eric" = import ../home; }; };
}
