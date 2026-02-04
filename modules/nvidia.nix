{ config, lib, pkgs, ... }:

{
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      nvidiaBusId = "PCI:8:0:0";
      intelBusId = "PCI:1:0:0";
    };
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
    dpi = 110;
  };

  environment.variables = {
    GDK_SCALE = "0.5";
    ENABLE_HDR_WSI = "1";
  };

  environment.systemPackages = with pkgs; [
    nvidia-docker
    egl-wayland
    nvidia-vaapi-driver
    cudaPackages.cudatoolkit
  ];
}
