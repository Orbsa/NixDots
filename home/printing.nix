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
  home.packages = [ pkgs.orca-slicer orca-slicer-mime-type freecad-with-workaround ];
}
