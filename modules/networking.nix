{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  services = {
    zerotierone = {
      enable = true;
      joinNetworks = [ "35c192ce9b138e32" "af78bf9436e7d202" ];
    };
    mullvad-vpn.enable = true;
  };

  environment.systemPackages = with pkgs; [ mullvad-vpn mullvad ];
}
