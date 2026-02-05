{ lib, stdenv, fetchurl, autoPatchelfHook, alsa-lib, dbus, libX11, libXcursor
, libXext, libXrandr, libGL, freetype, cairo, }:

let
  archMap = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-KSuU9jXoreyV8jKA/JTxtt2VS4qUQPPlG36fqovb5UM=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-v53BN9UL9WnsUkPGzNge7pg2meFHAESpgO6zcXvFXSg=";
    };
    armv7l-linux = {
      arch = "armhf";
      hash = "sha256-J3KnG5pRu135VRPy9JdYsJTO0wo5F3qnVgBNvik5h7o=";
    };
    riscv64-linux = {
      arch = "riscv64";
      hash = "sha256-MtaLZJ41Zz5lJVQ6PU4/yv9cjxlPfsAfFafMsooctDU=";
    };
  };
  archInfo = archMap.${stdenv.hostPlatform.system} or (throw
    "Unsupported platform: ${stdenv.hostPlatform.system}");
in stdenv.mkDerivation rec {
  pname = "aida-x";
  version = "1.1.0";

  src = fetchurl {
    url =
      "https://github.com/AidaDSP/AIDA-X/releases/download/${version}/AIDA-X-${version}-linux-${archInfo.arch}.tar.xz";
    hash = archInfo.hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs =
    [ alsa-lib dbus libX11 libXcursor libXext libXrandr libGL freetype cairo ];

  dontBuild = true;

  sourceRoot = "AIDA-X-${version}";

  installPhase = ''
    mkdir -p $out/bin $out/lib/lv2 $out/lib/vst $out/lib/vst3 $out/lib/clap

    # Standalone
    cp AIDA-X $out/bin/

    # LV2
    cp -r AIDA-X.lv2 $out/lib/lv2/

    # VST2
    cp AIDA-X-vst2.so $out/lib/vst/

    # VST3
    cp -r AIDA-X.vst3 $out/lib/vst3/

    # CLAP
    cp AIDA-X.clap $out/lib/clap/
  '';

  meta = {
    description = "AIDA-X, an Amp Model Player leveraging AI";
    homepage = "https://github.com/AidaDSP/AIDA-X";
    license = lib.licenses.gpl3;
    platforms = builtins.attrNames archMap;
  };
}
