{ config, lib, pkgs, inputs, ... }:

{
  boot.extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];

  programs = {
    steam = {
      enable = true;
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

  networking.firewall = {
    allowedTCPPorts = [ 3074 ];
    allowedTCPPortRanges = [ { from = 27014; to = 27050; } ];
    allowedUDPPorts = [ 3074 3478 27036 ];
    allowedUDPPortRanges = [
      { from = 4379; to = 4380; }
      { from = 27000; to = 27031; }
    ];
  };

  environment.systemPackages = with pkgs;
    [
      (import ../pkgs/noita-entangled-worlds.nix { pkgs = pkgs; })
      (steam.override {
        extraProfile = ''
          export VK_ICD_FILENAMES=${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json:$VK_ICD_FILENAMES
        '';
      })
      dxvk.out
      dxvk
      dxvk_2
      lutris
      steamtinkerlaunch
      r2modman
      winetricks
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
      # Games
      runelite
      hdos
      runescape
      hypnotix
  ];
}
