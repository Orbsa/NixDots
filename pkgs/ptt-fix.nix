{ pkgs }:

(pkgs.buildGoModule.override { go = pkgs.go_1_26; }) {
  pname = "ptt-fix";
  version = "unstable-2026-02-16";

  src = pkgs.fetchFromGitHub {
    owner = "DeedleFake";
    repo = "ptt-fix";
    rev = "3becfced43a4b1af4470292f78932fee51433b0f";
    hash = "sha256-R/WSqzETOlH70dv9rZTowBaB7xCmUKVVZSGUVdutN60=";
  };

  vendorHash = "sha256-h/8T/nddfpIkYec1ZIQKSyQKxwUdfz8adad2nfeR2sU=";

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = with pkgs; [
    xdotool
    xorg.libX11
    xorg.libXtst
    xorg.libXi
    xorg.libXinerama
    xorg.libXext
  ];

  meta = with pkgs.lib; {
    description = "Push-to-talk fix for Wayland via X11 key forwarding";
    homepage = "https://github.com/DeedleFake/ptt-fix";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "ptt-fix";
  };
}
