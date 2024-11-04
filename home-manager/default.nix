{ ... }: {
  imports = [
    ./neovim.nix
    ./borders.nix
    ./aerospace.nix
    ./tmux.nix
    ./home.nix
  ];
  
  home.shellAliases = {
    eZ = "nvim ~/nix-config";
    Ze = "nix run nix-darwin -- switch --flake ~/nix-config/";
  };

}
