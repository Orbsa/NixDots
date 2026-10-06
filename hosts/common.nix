{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../shared/packages.nix
    ../modules/audio.nix
    ../modules/boot.nix
    ../modules/desktop.nix
    ../modules/media.nix
    ../modules/networking.nix
    ../modules/users.nix
    inputs.agenix.nixosModules.default
    ../modules/tailscale.nix
  ];

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/persist/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys =
      [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "bambu-studio.cachix.org-1:6Ygd0p7L9jY6dg/v6TzR1XrwqQa9C42ATLwsBmxD8JM=" ];
    max-jobs = 8;
    cores = 4;
  };

  programs.fish.enable = true;

  time.timeZone = "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
    options snd-intel-dspcfg dsp_driver=1
    options snd-hda-intel power_save=0 power_save_controller=N
  '';

  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
      python3 = prev.python3.override {
        packageOverrides = pyFinal: pyPrev: {
          mpv = pyPrev.mpv.overridePythonAttrs (_: { doCheck = false; });
        };
      };
      vimPlugins = prev.vimPlugins.extend (_: vprev: {
        neotest = vprev.neotest.overrideAttrs (_: { doCheck = false; });
      });
    })
  ];

  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    plemoljp-nf
    google-fonts
    nerd-fonts.blex-mono
    ibm-plex
  ];

  programs = {
    dconf.enable = true;
    mtr.enable = true;
    coolercontrol.enable = true;
  };

  # Admin public key for every host that imports this module (enix, thinix).
  # Required now that password authentication is disabled below.
  users.users.eric.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos"
  ];

  services = {
    locate = {
      enable = true;
    };

    openssh = {
      enable = true;
      # Public-key only. NixOS defaults PasswordAuthentication (and PAM
      # keyboard-interactive) to true, which left these hosts reachable with
      # the local account password. `getty.autologinUser` is opt-in per host
      # (only enix, the desktop) — a headless host must never autologin.
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    blueman.enable = true;
    flatpak.enable = true;
    geoclue2.enable = true;
    #sunshine = {
      #enable = true;
      #autoStart = true;
      #capSysAdmin = true;
      #openFirewall = true;
    #};
  };

  # Persist flatpak data across ephemeral root rollbacks
  systemd.tmpfiles.rules = [
    "d /persist/var/lib/flatpak 0755 root root -"
    "L /var/lib/flatpak - - - - /persist/var/lib/flatpak"
  ];


  system.stateVersion = "24.05";
}
