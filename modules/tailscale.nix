{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.agenix.nixosModules.default ];

  age.secrets.ts-auth-key.file = ../secrets/ts-auth-key.age;

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.ts-auth-key.path;
    extraUpFlags = [ "--ssh" ];
  };
}
