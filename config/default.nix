{ pkgs, ... }:
{
  imports = [
     ./programs
    ./stylix.nix
  ];
  #imports = [ ./home.nix ];
}
