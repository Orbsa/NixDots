# Darwin host: KN72DN4D3W (MacBook)
{ pkgs, ... }:

{
  imports = [
    ../shared/packages.nix
    ../darwin
  ];

  nix.settings = {
    extra-trusted-users = [ "ebell" ];
    extra-experimental-features = "configurable-impure-env";
  };
  system.primaryUser = "ebell";

  # Darwin-specific packages (dev SDKs, LSPs, etc.)
  environment.systemPackages = with pkgs; [
    claude-code
    rustup
    cargo
    nodejs
    vscode-langservers-extracted
    vscode-extensions.vadimcn.vscode-lldb
  ];
}
