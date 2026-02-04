{ config, pkgs, ... }:

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
      settings = {
        mpv_ext = true;
      };
    };
  };
}
