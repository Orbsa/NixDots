{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./shell.nix
    ./neovim.nix
    ./tmux.nix
    ./aerospace.nix
    ./borders.nix
  ];

  home = {
    username = "ebell";
    homeDirectory = "/Users/ebell";
    stateVersion = "23.11";
    shellAliases = {
      eZ = "nvim -c 'cd ~/nix-config/'";
      Ze = "sudo nix run nix-darwin -- switch --flake ~/nix-config/";
      eV = "nvim -c 'cd ~/.config/nvim/lua/orbsa'";
    };
  };

  programs.bash.enable = true;

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
