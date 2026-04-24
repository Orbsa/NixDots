{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  systemd.services.zerotier-route = {
    description = "Add static route over ZeroTier interface";
    after = [ "zerotierone.service" ];
    bindsTo = [ "zerotierone.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      for i in $(seq 1 30); do
        ip link show zthnhfqrru 2>/dev/null && break
        sleep 1
      done
      ip route add 10.0.0.0/24 via 192.168.196.2 dev zthnhfqrru 2>/dev/null || true

      # Wait for OrbGamers (BO3 LAN) interface
      for i in $(seq 1 30); do
        ip link show ztrfydyvdr 2>/dev/null && break
        sleep 1
      done
      # Low metric so BO3 prefers ZeroTier for LAN discovery
      ip route del 192.168.2.0/24 dev ztrfydyvdr 2>/dev/null || true
      ip route add 192.168.2.0/24 dev ztrfydyvdr proto kernel scope link src 192.168.2.160 metric 1 2>/dev/null || true
    '';
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
    };
  };

  services = {
    zerotierone = {
      enable = true;
      joinNetworks = [ "3efa5cb78a60e3fb" "af78bf9436e7d202" ];
    };
    mullvad-vpn.enable = true;
  };

  environment.systemPackages = with pkgs; [ mullvad-vpn mullvad ];
}
