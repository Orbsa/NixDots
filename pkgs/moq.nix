# moq / moq-relay — the Media over QUIC CLI and relay.
#
# Why a fetchurl of the release tarball rather than the project's own flake:
# moq-dev/moq ships a flake, but its package builds the Rust workspace from
# source and only its tagged releases are in the Cachix cache, which a flake
# input would not be *trusted* to substitute from without adding that cache to
# this host's trusted keys. The release tarball is the same artefact the
# project's own `curl https://moq.sh | sh` installer uses, and pinning it by
# hash keeps the build reproducible without compiling Rust on a loaded box.
#
# The binaries are generic glibc-linked Linux builds (only libc/libm needed, no
# OpenSSL), so autoPatchelfHook is all it takes to make them run on NixOS.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  glibc,
}:

let
  mkMoq =
    {
      pname,
      version,
      tag,
      archive,
      hash,
      description,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version;

      src = fetchurl {
        url = "https://github.com/moq-dev/moq/releases/download/${tag}/${archive}.tar.gz";
        inherit hash;
      };

      nativeBuildInputs = [ autoPatchelfHook ];
      # The binary's only shared-library dependencies are libc and libm.
      buildInputs = [ glibc ];

      # The tarball unpacks to <archive>/{bin/<pname>,LICENSE-*,README.md}.
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 ${archive}/bin/${pname} $out/bin/${pname}
        runHook postInstall
      '';

      meta = {
        inherit description;
        homepage = "https://moq.dev/";
        license = with lib.licenses; [ mit asl20 ];
        platforms = [ "x86_64-linux" ];
        mainProgram = pname;
      };
    };
in
{
  moq = mkMoq {
    pname = "moq";
    version = "0.14.2";
    tag = "moq-cli-v0.14.2";
    archive = "moq-cli-v0.14.2-x86_64-unknown-linux-gnu";
    hash = "sha256-DSJNFY57rsu2Qv+JoCqBacxYJW2UfJaC6uWyld8KoJY=";
    description = "Media over QUIC: publish, play, convert and gate broadcasts";
  };

  moq-relay = mkMoq {
    pname = "moq-relay";
    version = "0.17.2";
    tag = "moq-relay-v0.17.2";
    archive = "moq-relay-v0.17.2-x86_64-unknown-linux-gnu";
    hash = "sha256-/DXdoeRdPwQ59UJZRnSR0HndQJdZKCZg1FkOZgRKZuQ=";
    description = "Media over QUIC relay: routes broadcasts from publishers to subscribers";
  };
}
