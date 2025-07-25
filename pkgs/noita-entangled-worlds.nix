{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "noita_entangled_worlds";
  version = "0.32.3";

  # Fetch the correct Linux zip file
  src = pkgs.fetchurl {
    url = "https://github.com/IntQuant/noita_entangled_worlds/releases/download/v${version}/noita-proxy-linux.zip";
     sha256 = "sha256-ycVk2EmzwO30OQ5qPZDN9MkUWQ3XAffqe6Lf57wmtbU=";
  };

  # Include unzip and makeWrapper in the build environment
  nativeBuildInputs = [ pkgs.unzip pkgs.makeWrapper pkgs.steam-run ];

  unpackPhase = ''
    mkdir source
    unzip $src -d source
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp source/noita_proxy.x86_64 $out/bin/noita-proxy-bin
    cp source/libsteam_api.so $out/bin/

    # Create a wrapper script for running the binary with steam-run
    makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/noita-proxy \
      --add-flags "$out/bin/noita-proxy-bin"
  '';

  meta = with pkgs.lib; {
    description = "Noita Entangled Worlds - Prebuilt binary for Linux";
    homepage = "https://github.com/IntQuant/noita_entangled_worlds";
    license = licenses.mit;
    maintainers = [ maintainers.yourname ];
    platforms = platforms.linux;
  };
}

