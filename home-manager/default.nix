{ ... }: {
  imports = [
    ./neovim.nix
    ./borders.nix
    ./aerospace.nix
    ./fish.nix
    ./tmux.nix
    ./home.nix
  ];
  
  home.shellAliases = {
    eZ = "nvim -c 'cd ~/nix-config'";
    Ze = "sudo nix run nix-darwin -- switch --flake ~/nix-config/";
    eV = "nvim -c 'cd ~/.config/nvim/lua/orbsa'";
  };

}
