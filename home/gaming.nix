{ config, pkgs, lib, osConfig, ... }:
{
  config = lib.mkIf osConfig.programs.steam.enable {
    programs.mangohud.enable = true;

    # Opts the Steam client into the "publicbeta" branch (Settings -> Interface
    # -> Client Beta Participation -> Steam Beta Update). The bootstrap
    # (steam.sh) reads this marker to select the beta client; remove this entry
    # to opt back out.
    xdg.dataFile."Steam/package/beta" = {
      text = "publicbeta";
      force = true;
    };

    # Additionally force the SteamRT3 (sniper) client; steam.sh only execs
    # $STEAMROOT/steamrt64/steam when this marker AND the beta opt-in above exist.
    xdg.dataFile."Steam/.steam-enable-steamrt64-client".text = "";
  };
}
