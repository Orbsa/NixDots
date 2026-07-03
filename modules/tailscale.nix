{ config, lib, pkgs, inputs, ... }:

{
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
  };
}
