# Jagex Launcher (RuneScape) — upstream: pkgs/by-name/ja/jagex-launcher
{ pkgs, lib, fetchurl, appimageTools }:

let
  pname = "jagex-launcher";
  version = "0.1.1";

  src = fetchurl {
    url = "https://rs-launcher-updates.runescape.com/production/linux/x64/releases/${version}/jagex-launcher-beta-linux-x86_64.AppImage";
    hash = "sha256-VUWfxwvnVTjfsA8lXYGBG6SYKQDbzhZQqrgApiz7lIE=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  profile = "export APPIMAGE_EXTRACT_AND_RUN=1";

  extraPkgs = pkgs: with pkgs; [
    libsecret
    nss
    mesa
  ];

  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/jagex-launcher.png \
      $out/share/pixmaps/jagex-launcher.png

    install -Dm644 ${appimageContents}/jagex-launcher.desktop \
      $out/share/applications/${pname}.desktop

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
  '';

  meta = with lib; {
    description = "Jagex Launcher for RuneScape game clients";
    homepage = "https://www.runescape.com/";
    downloadPage = "https://rs-launcher-updates.runescape.com/production/linux/x64/latest/";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "jagex-launcher";
    platforms = [ "x86_64-linux" ];
  };
}

