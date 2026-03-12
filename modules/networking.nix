{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  networking.interfaces."zthnhfqrru".ipv4.routes = [
    { address = "10.0.0.0"; prefixLength = 24; via = "192.168.196.2"; }
  ];

  services = {
    zerotierone = {
      enable = true;
      joinNetworks = [ "35c192ce9b138e32" "af78bf9436e7d202" ];
    };
    mullvad-vpn.enable = true;
  };

  environment.systemPackages = with pkgs; [ mullvad-vpn mullvad ];
}
