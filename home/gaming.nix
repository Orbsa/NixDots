{ config, pkgs, lib, osConfig, ... }:
{
  config = lib.mkIf osConfig.programs.steam.enable {
    programs.mangohud.enable = true;
  };
}
