{ stdenvNoCC, bun }:

# Homelab dashboard — a static site built from data/services.json by a small
# Bun + TypeScript app (src/build.ts). The build is deterministic and has no
# runtime dependencies; the only runtime artifact is dist/index.html plus the
# tiny static server src/serve.ts.
stdenvNoCC.mkDerivation {
  pname = "homelab-homepage";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    runHook preBuild
    # Bun needs a writable HOME for its module cache.
    export HOME="$TMPDIR"
    mkdir -p dist
    ${bun}/bin/bun src/build.ts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r dist "$out/dist"
    cp -r src  "$out/src"
    runHook postInstall
  '';
}
