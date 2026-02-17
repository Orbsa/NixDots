{ pkgs, lib, inputs, ... }:

let
  qsPackage = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

  qtImports = with pkgs.kdePackages; [
    qtbase
    qtdeclarative
    qtsvg
    qtwayland
    qt5compat
    qtimageformats
    qtmultimedia
    qtpositioning
    qtsensors
    qtquicktimeline
    qttools
    qttranslations
    qtvirtualkeyboard
    qtwebsockets
    syntax-highlighting
    kirigami.unwrapped
  ];

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.build
    ps.cffi
    ps.click
    ps."dbus-python"
    ps."kde-material-you-colors"
    ps.libsass
    ps.loguru
    ps."material-color-utilities"
    ps.materialyoucolor
    ps.numpy
    ps.pillow
    ps.psutil
    ps.pycairo
    ps.pygobject3
    ps.pywayland
    ps.setproctitle
    ps."setuptools-scm"
    ps.tqdm
    ps.wheel
    ps."pyproject-hooks"
    ps.opencv4
  ]);

  fakeVenv = pkgs.runCommand "quickshell-fake-venv" {} ''
    mkdir -p $out/bin

    cat > $out/bin/activate << 'ACTIVATE'
    export VIRTUAL_ENV="${pythonEnv}"
    export PATH="${pythonEnv}/bin:$PATH"
    deactivate () {
        return 0
    }
    ACTIVATE

    ln -s ${pythonEnv}/bin/python $out/bin/python
    ln -s ${pythonEnv}/bin/python3 $out/bin/python3

    cat > $out/pyvenv.cfg << EOF
    home = ${pythonEnv}/bin
    include-system-site-packages = false
    version = 3.11.0
    EOF
  '';

  wrappedQuickshell = pkgs.writeShellScriptBin "qs" ''
    export QT_PLUGIN_PATH="${lib.makeSearchPath "lib/qt-6/plugins" (qtImports ++ [qsPackage])}:${lib.makeSearchPath "lib/qt6/plugins" (qtImports ++ [qsPackage])}:${lib.makeSearchPath "lib/plugins" (qtImports ++ [qsPackage])}"
    export QML2_IMPORT_PATH="${lib.makeSearchPath "lib/qt-6/qml" (qtImports ++ [qsPackage])}:${lib.makeSearchPath "lib/qt6/qml" (qtImports ++ [qsPackage])}"
    export XDG_DATA_DIRS="${lib.makeSearchPath "share" [
      pkgs.adwaita-icon-theme
      pkgs.hicolor-icon-theme
      pkgs.papirus-icon-theme
      pkgs.gnome-icon-theme
      pkgs.kdePackages.breeze-icons
      pkgs.lxqt.pavucontrol-qt
    ]}:''${HOME}/.nix-profile/share:''${HOME}/.local/share:/etc/profiles/per-user/''${USER}/share:/run/current-system/sw/share:/usr/share:''${XDG_DATA_DIRS}"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export QT_QPA_PLATFORMTHEME=gtk3
    exec ${qsPackage}/bin/qs "$@"
  '';
in
{
  environment.sessionVariables = {
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${fakeVenv}";
    ILLOGICAL_IMPULSE_DOTFILES_SOURCE = "$HOME/.config";
    qsConfig = "$HOME/.config/quickshell/ii";
    QT_STYLE_OVERRIDE = "";
  };

  environment.systemPackages = with pkgs; [
    wrappedQuickshell
    qt6Packages.qt6ct
    pythonEnv

    # KDE integration
    kdePackages.polkit-kde-agent-1
    kdePackages.bluedevil
    kdePackages.plasma-nm
    kdePackages.plasma-workspace
    kdePackages.kde-cli-tools
    kdePackages.qt3d
    kdePackages.kirigami
    kdePackages.kdialog

    # Icon themes
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme
    gnome-icon-theme
    kdePackages.breeze-icons

    # Qt5 compat
    libsForQt5.breeze-icons
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qtsvg

    # Secrets
    libsecret
  ] ++ qtImports;
}
