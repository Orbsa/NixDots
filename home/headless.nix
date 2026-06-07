{ pkgs, lib, config, ... }:

{
  imports = [
    ./common.nix
    ./shell.nix
    ./neovim.nix
    ./tmux.nix
  ];

  home.packages = with pkgs; [
    nil # Nix LSP
  ];

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    enableSshSupport = false;
    pinentry.package = pkgs.pinentry-curses;
  };

  services.ssh-agent.enable = true;
}
