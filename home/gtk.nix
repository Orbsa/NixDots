{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };

    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    font = {
      name = "Google Sans Flex Medium";
      size = 11;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-name = "Google Sans Flex Medium 11";
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  xdg.configFile."gtk-4.0/gtk.css" = {
    force = true;
    text = "";
  };

  xdg.configFile."lxqt/lxqt.conf" = {
    force = true;
    text = ''
      [General]
      icon_theme=Papirus-Dark
    '';
  };

  xdg.configFile."qt5ct/qt5ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=adwaita-dark
    '';
  };

  xdg.configFile."qt6ct/qt6ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=adwaita-dark
    '';
  };
}
