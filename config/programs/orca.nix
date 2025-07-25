{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let inherit (lib) getExe ;
  # software rendering workaround for nvidia, see:
  # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
  orca-slicer-with-workaround = pkgs.symlinkJoin {
    name = "orca-slicer";
    paths = [
      pkgs.orca-slicer
      (pkgs.writeTextFile {
        name = "model-step.xml";
        text = # xml
          ''
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
    buildInputs = with pkgs; [
      makeWrapper
      shared-mime-info
    ];
    postBuild =
        ''
          wrapProgram $out/bin/orca-slicer \
            --set __GLX_VENDOR_LIBRARY_NAME mesa \
            --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
            --set MESA_LOADER_DRIVER_OVERRIDE zink \
            --set GALLIUM_DRIVER zink \
            --set WEBKIT_DISABLE_DMABUF_RENDERER 1
        '';
    meta.mainProgram = "orca-slicer";
  };
  # running freecad with strace doesn't trigger the segfault
  # https://github.com/NixOS/nixpkgs/issues/366299#issuecomment-2653093371
  freecad-with-workaround = pkgs.symlinkJoin {
    name = "FreeCAD";
    paths = [ pkgs.freecad-wayland ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = # sh
      ''
        wrapProgram "$out/bin/FreeCAD"
        substituteInPlace "$out/bin/FreeCAD" --replace-fail '"/nix/store' '${getExe pkgs.strace} "/nix/store'
      '';
    meta.mainProgram = "FreeCAD";
  };
in
{
  home.packages = [
    # orca-slicer doesn't show the prepare / preview pane on nvidia 565:
    # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
    orca-slicer-with-workaround
    freecad-with-workaround
  ];

  xdg = {
    mimeApps = {
      associations.added."model/step" = "OrcaSlicer.desktop";
      # allow orca-slicer to be open bambu studio links
      defaultApplications = {
        "model/step" = "OrcaSlicer.desktop";
        "x-scheme-handler/orcaslicer" = "OrcaSlicer.desktop";
        "x-scheme-handler/bambustudio" = "OrcaSlicer.desktop"; # makerworld
        "x-scheme-handler/prusaslicer" = "OrcaSlicer.desktop"; # printables
      };
    };
  };
}
