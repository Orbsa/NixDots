{ pkgs, ... }:

# RuneLite (Java) uses DirectAudioDeviceProvider which opens ALSA plughw
# devices directly, bypassing PipeWire. Since we listen on S/PDIF, Java's
# audio goes to the wrong output. This module sets up:
#   1. snd-aloop virtual loopback card
#   2. ALSA config redirecting plughw → loopback device 1
#   3. Wrapper script bridging loopback device 0 → PipeWire S/PDIF
{
  boot.extraModprobeConfig = ''
    options snd-aloop enable=1 pcm_substreams=1 index=10
  '';
  boot.kernelModules = [ "snd-aloop" ];

  environment.etc."asound.conf".text = ''
    pcm.!plughw {
      @args [ CARD DEV SUBDEV ]
      @args.CARD {
        type string
        default "0"
      }
      @args.DEV {
        type integer
        default 0
      }
      @args.SUBDEV {
        type integer
        default -1
      }
      type plug
      slave.pcm {
        type hw
        card Loopback
        device 1
      }
      hint {
        show on
        description "Audio via PipeWire (loopback)"
      }
    }
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "runelite" ''
      ${pkgs.alsa-utils}/bin/arecord \
        -D hw:Loopback,0 -f S16_LE -r 44100 -c 2 -t wav \
      | ${pkgs.pipewire}/bin/pw-play \
        --target=alsa_output.pci-0000_00_1f.3.iec958-stereo - &
      _BRIDGE_PID=$!
      trap "kill $_BRIDGE_PID 2>/dev/null; wait $_BRIDGE_PID 2>/dev/null" EXIT
      sleep 1
      ${pkgs.runelite}/bin/runelite "$@"
    '')
  ];
}
