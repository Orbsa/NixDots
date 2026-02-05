{ config, lib, pkgs, ... }:

let
  inherit (lib) getExe;
  orca-slicer-with-workaround = pkgs.symlinkJoin {
    name = "orca-slicer";
    paths = [
      pkgs.orca-slicer
      (pkgs.writeTextFile {
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
      })
    ];
    buildInputs = with pkgs; [ makeWrapper shared-mime-info ];
    postBuild = ''
      wrapProgram $out/bin/orca-slicer \
        --set __GLX_VENDOR_LIBRARY_NAME mesa \
        --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
        --set MESA_LOADER_DRIVER_OVERRIDE zink \
        --set GALLIUM_DRIVER zink \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
    meta.mainProgram = "orca-slicer";
  };
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
in {
  home.packages = [ orca-slicer-with-workaround freecad-with-workaround ];

  xdg = {
    mimeApps = {
      associations.added."model/step" = "OrcaSlicer.desktop";
      defaultApplications = {
        "model/step" = "OrcaSlicer.desktop";
        "x-scheme-handler/orcaslicer" = "OrcaSlicer.desktop";
        "x-scheme-handler/bambustudio" = "OrcaSlicer.desktop";
        "x-scheme-handler/prusaslicer" = "OrcaSlicer.desktop";
      };
    };
  };
}
