let
  # RTX 2080
  gpuIDs = [
    "10de:1e87" # Graphics
    "10de:10f8" # Audio
    "10de:1ad8" # USB
    "10de:1ad9" # Type-C
    "0000:02:00.0" #Windows NVME
  ];
in { pkgs, lib, config, ... }: {
  options.vfio.enable = with lib;
    mkEnableOption "Configure the machine for VFIO";

  config = let cfg = config.vfio;
  in {
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"

        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      kernelParams = [
        # enable IOMMU
        "intel_iommu=on"
        "iommu=pt" 
      ] ++ lib.optional cfg.enable
        # isolate the GPU
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
    };

    hardware.graphics.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;

    specialisation."VFIO".configuration = {
      system.nixos.tags = [ "with-vfio" ];
      vfio.enable = true;
    };
  };
}
