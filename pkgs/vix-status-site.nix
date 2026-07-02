{ lib, stdenv, src }:

stdenv.mkDerivation {
  pname = "vix-status-site";
  version = "0.1.0";
  inherit src;

  # Dependencies are fetched at runtime by the systemd service (ExecStartPre).
  # Nix sandbox has no network access, so bun install must run outside it.

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out"
    runHook postInstall
  '';

  meta = with lib; {
    description = "status.thyrsos.tv — Plex/services uptime page";
    license = licenses.unlicense;
    platforms = platforms.all;
  };
}
