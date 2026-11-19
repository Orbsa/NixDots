{ lib, pkgs, inputs, ... }:

{
  # This pad (045E:02FD, firmware 0x0903) advertises a 306-byte report descriptor
  # that is truncated mid-item: it opens 5 COLLECTIONs but closes only 3, ending
  # on a dangling `09 7c 15 00`. hid-core's parser rejects that outright
  # ("unbalanced collection at end of report description" -> "parse failed",
  # -EINVAL), so NO driver can bind — hid_xpadneo *and* hid_microsoft both fail —
  # and no /dev/input/event* ever appears. Steam is then blind to the pad even
  # though BLE/BR-EDR and BlueZ are perfectly happy.
  #
  # Upstream repaired this for issue #624 in "xpadneo, device: Fix up cached
  # truncated XB1S descriptor". That commit is in neither v0.11-pre nor the
  # 0.10.4 shipped by nixpkgs, so pin the master rev that has it (bump
  # deliberately, don't float).
  boot.kernelPackages = pkgs.linuxPackages.extend (final: prev: {
    xpadneo = prev.xpadneo.overrideAttrs (_: {
      version = "0.11-pre-unstable-2026-10-06";
      src = pkgs.fetchFromGitHub {
        owner = "atar-axis";
        repo = "xpadneo";
        rev = "3879ba0f44e9bcfd500a5b92d02f83885f6b23c7";
        hash = "sha256-rOFMjAw0tsL3a+2Imo1GhDUe9OJxbRFVZLNKy7zkihE=";
      };
    });
  });

  # The boot.kernelPackages pin above is what feeds the NixOS option (which also
  # sets boot.kernelModules = [ "hid_xpadneo" ], so xpadneo registers before the
  # in-tree hid_microsoft — both claim hid:b0005g0001v0000045Ep000002FD, see
  # `modprobe -R`, and first registration wins the bind).
  hardware.xpadneo.enable = true;

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
    gamescope = {
      enable = true; 
      #capSysNice = true;
      args = [
        #"--expose-wayland"
        #"--adaptive-sync"
        #"--mangoapp"
        #"--prefer-output DP-4"
        #"--hdr-enabled"
        #"--rt"
      ];
      env = {
        DXVK_HDR = "1";
        #LD_LIBRARY_PATH = "";
        # LD_PRELOAD = "";
      };
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
  };

  networking.firewall = let
    sharedTCPPorts = [ 2626 3074 25565 80 ];
    sharedUDPPorts = [ 2626 3074 3478 25565 27036 80 ];
    sharedRanges = [
      { from = 4379; to = 4380; }
      { from = 27000; to = 27031; }
      { from = 27014; to = 27050; }
    ];
  in {
    allowedTCPPorts = sharedTCPPorts;
    allowedTCPPortRanges = sharedRanges;
    allowedUDPPorts = sharedUDPPorts;
    allowedUDPPortRanges = sharedRanges;
  };

  environment.systemPackages = with pkgs;
    [
      (import ../pkgs/noita-entangled-worlds.nix { pkgs = pkgs; })
      # Do NOT override steam's extraProfile to pin VK_ICD_FILENAMES.
      # nixpkgs' nvidia lib32 package ships .../share/vulkan/icd.d/nvidia_icd.json,
      # not nvidia_icd32.json, so that export injected a dead path (plus a trailing
      # ":" that resolves to $PWD). pressure-vessel honours VK_ICD_FILENAMES when it
      # decides which host drivers to expose per-arch, so the i386 scan found no ICD
      # and 32-bit DXVK died with "DxvkInstance::createInstance: Failed to create
      # Vulkan instance" (the .NET Arma 3 Launcher is 32-bit, hence no launch).
      # programs.steam already wires up 64- and 32-bit graphics; leave it alone.
      steam
      parsec-bin
      dxvk.out
      dxvk
      dxvk_2
      lutris
      steamtinkerlaunch
      gale
      winetricks
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
      # Games
      runelite
      bolt-launcher
      hdos
      #runescape
      hypnotix
      dolphin-emu
      prismlauncher
  ];
}
