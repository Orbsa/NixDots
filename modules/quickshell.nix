{ pkgs, ... }:

{
  imports = [ ./qt.nix ];

  boot.kernelModules = [ "i2c-dev" ];

  programs.ydotool.enable = true;

  services.udisks2.enable = true;

  fonts.packages = with pkgs; [
    material-symbols
    nerd-fonts.jetbrains-mono
    rubik
    twemoji-color-font
  ];

  users.users.eric.extraGroups = [ "video" "i2c" "input" ];

  environment.systemPackages = with pkgs; [
    #Quickshell stuffs
    easyeffects
    lxqt.pavucontrol-qt
    libdbusmenu-gtk3
    geoclue2
    ddcutil
    xdg-user-dirs
    yq-go
    adw-gtk3
    kdePackages.breeze-gtk
    kdePackages.breeze
    darkly
    darkly-qt5
    eza
    matugen
    readexpro
    libadwaita
    libsoup_3
    libportal-gtk4
    gobject-introspection
    hyprshot
    swappy
    tesseract
    wf-recorder
    wtype
    upower
    fuzzel
    glib
    imagemagick
    songrec
    translate-shell
    wlogout
    libqalculate
  ];
}
