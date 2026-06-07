{ inputs, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./enix-hardware.nix
    ../modules/gaming.nix
    ../modules/runelite.nix
    ../modules/nvidia.nix
    ../modules/audio.nix
    inputs.nelko.nixosModules.default
    #../modules/virtualisation.nix
    #../modules/vfio.nix
  ];

  # Hardware-specific packages for this host
  environment.systemPackages = with pkgs; [
    android-tools
    lm_sensors
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
  ];

  services.nelko-pl70e = {
    enable = true;
    macAddress = "DC:0D:30:5A:A7:F5";
  };

  networking = {
    hostName = "enix";
    hostId = "6241ca71";
    interfaces.enp4s0 = {
      ipv4.addresses = [{
        address = "10.0.1.7";
        prefixLength = 23;
      }];
    };
    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp4s0";
    };
    nameservers = [ "10.0.0.1" ];
  };

  home-manager = { users = { "eric" = import ../home; }; };
}
