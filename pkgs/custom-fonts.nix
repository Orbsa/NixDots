{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "custom-fonts";
  version = "1.0.0";

  src = ./fonts;

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/fonts/custom *.{ttf,otf} 2>/dev/null || true
    runHook postInstall
  '';

  meta = with lib; {
    description = "Custom local fonts";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
