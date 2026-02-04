{ config, pkgs, ... }:

{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    htop
    fortune
  ];
}
