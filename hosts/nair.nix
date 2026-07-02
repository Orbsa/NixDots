# Darwin host: Nair (MacBook — eric's personal laptop)
{ pkgs, ... }:

{
  imports = [
    ../shared/packages.nix
    ../darwin/nair.nix
    ../modules/tailscale-darwin.nix
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
