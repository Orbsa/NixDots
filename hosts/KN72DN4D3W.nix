# Darwin host: KN72DN4D3W (MacBook)
{ pkgs, ... }:

{
  imports = [
    ../shared/packages.nix
    ../darwin
  ];

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
