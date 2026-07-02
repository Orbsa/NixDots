{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.agenix.darwinModules.default ];

  age.secrets.ts-auth-key.file = ../secrets/ts-auth-key.age;

  services.tailscale.enable = true;
}
