{
  lib,
  stdenv,
  fetchFromGitHub,
  cairo,
  jansson,
  curl,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "coolerdash";
  version = "3.2.3";

  src = fetchFromGitHub {
    owner = "damachine";
    repo = "coolerdash";
    rev = "v${finalAttrs.version}";
    hash = "sha256-EZ+YbMT9ZpJocwQXBd7PR309DSe1EyD0HRngRZD7+V4=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    cairo
    jansson
    curl
  ];

  strictDeps = true;

  # Strip -march=x86-64-v3: nixpkgs handles tuning
  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail '-march=$(MARCH)' ""
  '';

  makeFlags = [
    "CC=${stdenv.cc.targetPrefix}cc"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    pluginDir="$out/share/coolerdash"

    # Binary
    install -Dm755 bin/coolerdash "$out/bin/coolerdash"

    # Plugin manifest — CoolerControl discovers plugins by scanning
    # /var/lib/coolercontrol/plugins/*/manifest.toml
    install -Dm644 etc/coolercontrol/plugins/coolerdash/manifest.toml \
      "$pluginDir/manifest.toml"

    # Web UI
    install -Dm644 etc/coolercontrol/plugins/coolerdash/ui/index.html \
      "$pluginDir/ui/index.html"

    # Assets
    install -Dm644 images/shutdown.png "$pluginDir/shutdown.png"
    install -Dm644 images/coolerdash.png "$pluginDir/coolerdash.png"

    # Documentation
    install -Dm644 README.md "$pluginDir/README.md"
    install -Dm644 CHANGELOG.md "$pluginDir/CHANGELOG.md"
    install -Dm644 VERSION "$pluginDir/VERSION"

    # License
    install -Dm644 LICENSE "$out/share/licenses/coolerdash/LICENSE"

    # Default mutable configs (copied to /var/lib at runtime via tmpfiles)
    install -Dm644 etc/coolercontrol/plugins/coolerdash/config.json \
      "$pluginDir/config.json.default"
    printf '{\n  "access_token": ""\n}\n' > "$pluginDir/credentials.json.default"

    # Version substitution
    substituteInPlace "$pluginDir/manifest.toml" \
      --replace-fail '{{VERSION}}' '${finalAttrs.version}'
    substituteInPlace "$pluginDir/ui/index.html" \
      --replace-fail '{{VERSION}}' '${finalAttrs.version}'

    # Fix executable path in manifest to point at the nix store binary
    substituteInPlace "$pluginDir/manifest.toml" \
      --replace-fail '/usr/libexec/coolerdash/coolerdash' "$out/bin/coolerdash"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Plug-in for CoolerControl that extends LCD functionality";
    homepage = "https://github.com/damachine/coolerdash";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
    mainProgram = "coolerdash";
  };
})
