{ pkgs, ... }: {
  imports = [
    ./common.nix
    ./homebrew-nair.nix
  ];

  system.primaryUser = "eric";
}
