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
    # Was "6241ca71" — the same value as enix. hostId must be unique per machine
    # (journal identity, DHCP, machine-scoped state).
    hostId = "acc2573c";
  };

  home-manager = { users = { "eric" = import ../home; }; };
}
