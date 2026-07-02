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
    enableSshSupport = true;
    pinentry.package = lib.mkDefault pkgs.pinentry-curses;
  };


  # Fix gpg-agent SSH socket ordering cycle.
  # set-SSH_AUTH_SOCK.service has DefaultDependencies=yes, which pulls in
  # basic.target, creating a cycle: gpg-agent-ssh.socket → set-SSH_AUTH_SOCK
  # → basic.target → sockets.target → gpg-agent-ssh.socket.
  xdg.configFile."systemd/user/set-SSH_AUTH_SOCK.service.d/break-cycle.conf".text = ''
    [Unit]
    DefaultDependencies=no
  '';

  services.ssh-agent.enable = false;
}
