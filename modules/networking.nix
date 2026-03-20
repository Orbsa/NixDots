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
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  services = {
    zerotierone = {
      enable = true;
      joinNetworks = [ "35c192ce9b138e32" "af78bf9436e7d202" ];
    };
    mullvad-vpn.enable = true;
  };

  environment.systemPackages = with pkgs; [ mullvad-vpn mullvad ];
}
