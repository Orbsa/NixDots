{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };

    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      name = "Adwaita";
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
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "Darkly";
  };
}
