{ config, pkgs, inputs, lib, osConfig, ... }:

let audioEnabled = osConfig.services.pipewire.enable or false;
in {
  imports = [
    ./common.nix
    ./shell.nix
    ./neovim.nix
    ./tmux.nix
    ./gtk.nix
    ./media.nix
    ./printing.nix
    ./gaming.nix
  ];

  home = {
    username = "eric";
    homeDirectory = "/home/eric";
    stateVersion = "24.05";
    shellAliases = {
      ls = "lsd";
      vim = "nvim";
      eZ = "cd ~/.config/nix; nvim home.nix";
      Ze = "sudo nixos-rebuild --flake /home/eric/.config/nix/ switch";
    };
    packages = with pkgs; [
      nil
    ];
  };

  xdg = {
    configFile = lib.mkIf audioEnabled {
      "yabridgectl/config.toml".text = ''
        plugin_dirs = [
          '/home/eric/.wine/drive_c/Program Files/Common Files',
          '/home/eric/.wine/drive_c/VST2',
          '/home/eric/.wine/drive_c/VST3',
        ]
        vst2_location = 'centralized'
        no_verify = false
        blacklist = []
      '';
    };
  };

  services = {
    kdeconnect.enable = true;
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };
}
