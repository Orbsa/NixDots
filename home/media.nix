{ config, pkgs, pkgs-stable, ... }:

{
  services = {
    mpd = {
      enable = true;
      musicDirectory = "~/Music";
      extraConfig = ''
        audio_output {
          type "pipewire"
          name "My PipeWire Output"
        }
      '';
    };
    plex-mpv-shim = {
      enable = true;
      package = pkgs-stable.plex-mpv-shim;
      settings = { mpv_ext = true; };
    };
    awww.enable = true;
  };
}
