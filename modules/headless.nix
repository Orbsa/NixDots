{ config, lib, pkgs, ... }:

{
  imports = [
    ../shared/packages.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  time.timeZone = lib.mkDefault "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.mtr.enable = true;

  services.openssh.enable = true;
  services.locate.enable = true;


  system.stateVersion = lib.mkDefault "24.05";
}
