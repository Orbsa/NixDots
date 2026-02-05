{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  services = {
    zerotierone = {
      enable = true;
      joinNetworks = [ "af78bf9436e7d202" ];
    };
    mullvad-vpn.enable = true;
  };

  environment.systemPackages = with pkgs; [ mullvad-vpn mullvad ];
}
