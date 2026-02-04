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
      eZ = "nvim -c 'cd ~/.config/nix'";
      Ze = "sudo nix run nix-darwin -- switch --flake ~/.config/nix/";
      eV = "nvim -c 'cd ~/.config/nvim/lua/orbsa'";
    };
  };

  programs.bash.enable = true;
}
