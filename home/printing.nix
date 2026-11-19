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
  # OrcaSlicer's Python plugin system (embedded CPython + capability registry) is
  # not in any release nixpkgs packages: v2.4.2 has no src/slic3r/plugin/ at all,
  # upstream says "Nightly builds or Releases greater than 2.4.2", and on `main`
  # the subsystem is compiled unconditionally but expects its own Python runtime
  # layout (`$ORIGIN/../libpython/lib`) plus a bundled `uv` for installing plugin
  # dependencies. Upstream's nightly AppImage already ships exactly that layout
  # (resources/tools/uv + libpython), so wrap the AppImage rather than
  # reimplementing an unsupported embedding layout in a source build.
  # NOTE: the nightly asset is a rolling target - when upstream rebuilds it this
  # hash goes stale. Refresh with:
  #   nix store prefetch-file --json \
  #     https://github.com/OrcaSlicer/OrcaSlicer/releases/download/nightly-builds/OrcaSlicer_Linux_AppImage_Ubuntu2404_nightly.AppImage
  #
  # The wrapper below keeps the fixes this box needs: the native-Wayland EGL path
  # leaves the 3D view blank (NixOS/nixpkgs#513195, upstream fix #534163 =
  # `withEGL = false`), so force the X11/GLX backend; the AppImage bundles no
  # libGL/libEGL, so point GL at NixOS' driver stack; and upstream's own AppRun
  # force-enables mesa/zink (`__GLX_VENDOR_LIBRARY_NAME=mesa` +
  # `MESA_LOADER_DRIVER_OVERRIDE=zink`) whenever it sees an NVIDIA renderer on
  # Wayland, which segfaults on this hybrid Intel+NVIDIA box
  # (`segfault ... in libnvidia-glcore.so`, GLCanvas3D::render <- post_init) -
  # `ZINK_DISABLE_OVERRIDE=1` is upstream's documented escape hatch for that.
  orca-slicer-nightly = pkgs.appimageTools.wrapType2 {
    pname = "orca-slicer";
    version = "nightly";
    src = pkgs.fetchurl {
      url = "https://github.com/OrcaSlicer/OrcaSlicer/releases/download/nightly-builds/OrcaSlicer_Linux_AppImage_Ubuntu2404_nightly.AppImage";
      hash = "sha256-i3Foqg6EXRtTUGo1PXlw4rDitRbWwgC7IUW9vkZDJ0A=";
    };
    # The AppImage does not bundle WebKitGTK 4.1 / libsoup 3 (it expects the host
    # to provide them) and neither is reachable otherwise: the payload aborts with
    # "missing host WebKitGTK 4.1 runtime libraries", or the loader fails on
    # libsoup-3.0.so.0. libsoup is not a top-level symlink in the FHS rootfs,
    # hence listing it explicitly.
    extraPkgs = pkgs: [ pkgs.webkitgtk_4_1 pkgs.libsoup_3 ];
  };
  orca-slicer = pkgs.symlinkJoin {
    name = "orca-slicer";
    paths = [ orca-slicer-nightly ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/orca-slicer \
        --set GDK_BACKEND x11 \
        --set ZINK_DISABLE_OVERRIDE 1 \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
        --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
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
