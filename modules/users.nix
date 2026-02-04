{ config, lib, pkgs, ... }:

{
  users = {
    mutableUsers = false;
    users = {
      root = {
        initialHashedPassword = "$y$j9T$U7UbLkyC3ehiUSraLjjTF0$VMAl8LHs0U.QfZrpU5UQ/HaPtnoOOWv3TmjwdAWsRy8";
      };
      eric = {
        isNormalUser = true;
        createHome = true;
        initialHashedPassword = "$y$j9T$LGtqcLijoBEb9Ap8WVeAZ0$7ZMSUzOEVrFsF4R2J8Z.aZc6e7WPBY/OAYnoMBZNM41";
        extraGroups = [ "wheel" "qemu-libvirtd" "libvirtd" "disk" "audio" ];
        uid = 1000;
        home = "/home/eric";
        shell = pkgs.fish;
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;
}
