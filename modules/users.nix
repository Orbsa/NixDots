{ config, lib, pkgs, ... }:

# This repository is public. Credential material must never be inlined here —
# password hashes included. `hashedPassword`/`initialHashedPassword` were
# previously committed in the clear (offline-crackable, and identical on every
# host). Password hashes now come from agenix, declared on the host that needs
# them; see hosts/enix.nix and ../secrets/.
{
  users = {
    mutableUsers = false;
    users = {
      # Locked. Root is reachable through `sudo` from wheel (NOPASSWD below).
      root.hashedPassword = "!";

      eric = {
        isNormalUser = true;
        createHome = true;
        extraGroups = [ "wheel" "qemu-libvirtd" "libvirtd" "disk" "audio" "dialout" ];
        uid = 1000;
        home = "/home/eric";
        shell = pkgs.fish;
        # Password: age.secrets.eric-password-hash (declared per host).
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;
}
