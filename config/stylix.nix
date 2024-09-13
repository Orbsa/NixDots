{
  pkgs,
  inputs,
  ...
}: {
  #Stylix
  stylix = {
    enable = true;
    polarity = "dark";
    image = /home/eric/Pictures/papes/1709509373046161.jpg;
    base16Scheme = inputs.nix-colors.colorSchemes.oxocarbon-dark;
    cursor = { 
      package = pkgs.catppuccin-cursors;
      size = 18;
    };
    fonts = {
      sizes= {
        terminal = 12;
        desktop = 12;
        popups = 14;
        applications = 14;
      };
      monospace = {
        package = pkgs.plemoljp-nf;
        name = "PlemolJP Console NF";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "Dejavu Serif";
      };
    };
  };
}
