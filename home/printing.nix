{ config, lib, pkgs, ... }:

let
  inherit (lib) getExe;
  freecad-with-workaround = pkgs.symlinkJoin {
    name = "FreeCAD";
    paths = [ pkgs.freecad-wayland ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/FreeCAD"
      substituteInPlace "$out/bin/FreeCAD" --replace-fail '"/nix/store' '${
        getExe pkgs.strace
      } "/nix/store'
    '';
    meta.mainProgram = "FreeCAD";
  };
  # Upstream nixpkgs `orca-slicer` is served from cache.nixos.org. Overriding the
  # derivation (as the removed pkgs/orca-slicer overlay did) changes its hash and
  # forces a multi-hour full source build. Apply the NVIDIA/EGL workaround by
  # re-wrapping the cached binary instead: only this trivial wrapper is built.
  # Same env as nixpkgs' own `withNvidiaGLWorkaround` flag.
  orca-slicer = pkgs.symlinkJoin {
    name = "orca-slicer";
    paths = [ pkgs.orca-slicer ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/orca-slicer \
        --set __GLX_VENDOR_LIBRARY_NAME mesa \
        --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json \
        --set MESA_LOADER_DRIVER_OVERRIDE zink \
        --set GALLIUM_DRIVER zink \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
    meta.mainProgram = "orca-slicer";
  };
  orca-slicer-mime-type = pkgs.writeTextFile {
    name = "model-step.xml";
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="model/step">
              <glob pattern="*.step"/>
              <glob pattern="*.stp"/>
              <comment>STEP CAD File</comment>
          </mime-type>
      </mime-info>
    '';
    executable = true;
    destination = "/share/mime/packages/model-step.xml";
  };
in {
  home.packages = [ orca-slicer orca-slicer-mime-type ];
}
