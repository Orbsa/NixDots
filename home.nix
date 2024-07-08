{ config, pkgs, ... }:

{
  imports = [
    ./config/nixvim
    ./config/programs
  ];
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "eric";
    homeDirectory = "/home/eric";

    # Packages that should be installed to the user profile.
    packages = [
      pkgs.htop
      pkgs.fortune
      pkgs.prismlauncher
    ];
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.nixvim = {
    enable = true;
  };
  programs.fish = {
    enable = true;
    plugins = [
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    ];
  };
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
