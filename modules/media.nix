{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      mpv = super.mpv.override {
        scripts = with self.mpvScripts; [
          mpris
          sponsorblock-minimal
          evafast
          videoclip
        ];
      };
    })
  ];

  services.plex = {
    enable = false;
    openFirewall = true;
    user = "eric";
  };

  environment.systemPackages = with pkgs; [
    mpv
    yt-dlp
    tidal-hifi
    plex-desktop
    ncmpcpp
    revanced-cli
  ];
}
