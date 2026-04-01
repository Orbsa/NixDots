{ ... }:

let
  defaultBrowser = "zen-twilight.desktop";
in {
  xdg.systemDirs.data = [
    "/run/current-system/sw/share"
    "/home/eric/.nix-profile/share"
    "/etc/profiles/per-user/eric/share"
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browser / Web
      "text/html" = [ defaultBrowser ];
      "x-scheme-handler/http" = [ defaultBrowser ];
      "x-scheme-handler/https" = [ defaultBrowser ];
      "x-scheme-handler/about" = [ defaultBrowser ];
      "x-scheme-handler/unknown" = [ defaultBrowser ];
      "x-scheme-handler/chrome" = [ defaultBrowser ];
      "application/x-extension-htm" = [ defaultBrowser ];
      "application/x-extension-html" = [ defaultBrowser ];
      "application/x-extension-shtml" = [ defaultBrowser ];
      "application/x-extension-xhtml" = [ defaultBrowser ];
      "application/x-extension-xht" = [ defaultBrowser ];
      "application/xhtml+xml" = [ defaultBrowser ];
      "application/html" = [ defaultBrowser ];
      "application/http" = [ defaultBrowser ];
      "application/web" = [ defaultBrowser ];
      "html" = [ defaultBrowser ];
      "http" = [ defaultBrowser ];
      "https" = [ defaultBrowser ];

      # Mail
      "x-scheme-handler/mailto" = [ "userapp-Thunderbird-OJ57A3.desktop" ];
      "x-scheme-handler/mid" = [ "userapp-Thunderbird-OJ57A3.desktop" ];
      "message/rfc822" = [ "userapp-Thunderbird-OJ57A3.desktop" ];
      "x-scheme-handler/webcal" = [ "userapp-Thunderbird-0SDAD1.desktop" ];
      "x-scheme-handler/webcals" = [ "userapp-Thunderbird-0SDAD1.desktop" ];
      "text/calendar" = [ "userapp-Thunderbird-0SDAD1.desktop" ];
      "application/x-extension-ics" = [ "userapp-Thunderbird-0SDAD1.desktop" ];
      "x-scheme-handler/mailspring" = [ "mailspring.desktop" ];

      # Remote desktop
      "x-scheme-handler/rdp" = [ "org.remmina.Remmina.desktop" ];
      "x-scheme-handler/spice" = [ "org.remmina.Remmina.desktop" ];
      "x-scheme-handler/vnc" = [ "org.remmina.Remmina.desktop" ];
      "x-scheme-handler/remmina" = [ "org.remmina.Remmina.desktop" ];
      "application/x-remmina" = [ "org.remmina.Remmina.desktop" ];

      # Discord
      "x-scheme-handler/discord" = [ "vesktop.desktop" ];
      "x-scheme-handler/discord-409416265891971072" = [ "discord-409416265891971072.desktop" ];
      "x-scheme-handler/discord-424004941485572097" = [ "discord-424004941485572097.desktop" ];
      "x-scheme-handler/discord-396515353498484736" = [ "discord-396515353498484736.desktop" ];
      "x-scheme-handler/discord-402572971681644545" = [ "discord-402572971681644545.desktop" ];
      "x-scheme-handler/discord-696343075731144724" = [ "discord-696343075731144724.desktop" ];
      "x-scheme-handler/discord-610508934456934412" = [ "discord-610508934456934412.desktop" ];
      "x-scheme-handler/discord-742222376518811669" = [ "discord-742222376518811669.desktop" ];

      # Teams
      "x-scheme-handler/msteams" = [ "teams.desktop" ];

      # Media
      "image/png" = [ "imv.desktop" ];
      "application/octet-stream" = [ "mpv.desktop" ];
      "x-scheme-handler/tidal" = [ "tidal-hifi.desktop" ];

      # Files
      "inode/directory" = [ "Thunar.desktop" ];
      "application/x-gnome-saved-search" = [ "Thunar.desktop" ];

      # Other
      "x-scheme-handler/beatsaver" = [ "BeatSaberModManager-url-beatsaver.desktop" ];
      "x-scheme-handler/modelsaber" = [ "BeatSaberModManager-url-modelsaber.desktop" ];
      "x-scheme-handler/prusaslicer" = [ "PrusaSlicerURLProtocol.desktop" ];
      "hoppscotch" = [ "hoppscotch-handler.desktop" ];
      "x-scheme-handler/ror2mm" = [ "r2modman.desktop" ];
    };

    associations.added = {
      "x-scheme-handler/rdp" = [ "org.remmina.Remmina.desktop" ];
      "x-scheme-handler/spice" = [ "org.remmina.Remmina.desktop" ];
      "x-scheme-handler/vnc" = [ "org.remmina.Remmina.desktop" ];
      "x-scheme-handler/remmina" = [ "org.remmina.Remmina.desktop" ];
      "application/x-remmina" = [ "org.remmina.Remmina.desktop" ];
      "image/jpeg" = [ "imv.desktop" "feh.desktop" ];
      "application/x-xpinstall" = [ "thunderbird.desktop" ];
      "x-scheme-handler/mailto" = [ "userapp-Thunderbird-OJ57A3.desktop" "userapp-Thunderbird-7X08C1.desktop" ];
      "x-scheme-handler/mid" = [ "userapp-Thunderbird-OJ57A3.desktop" "userapp-Thunderbird-7X08C1.desktop" ];
      "x-scheme-handler/webcal" = [ "userapp-Thunderbird-0SDAD1.desktop" ];
      "x-scheme-handler/webcals" = [ "userapp-Thunderbird-0SDAD1.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
      "x-scheme-handler/http" = [ defaultBrowser ];
      "x-scheme-handler/https" = [ defaultBrowser ];
      "x-scheme-handler/chrome" = [ defaultBrowser ];
      "text/html" = [ defaultBrowser ];
      "application/x-extension-htm" = [ defaultBrowser ];
      "application/x-extension-html" = [ defaultBrowser ];
      "application/x-extension-shtml" = [ defaultBrowser ];
      "application/xhtml+xml" = [ defaultBrowser ];
      "application/x-extension-xhtml" = [ defaultBrowser ];
      "application/x-extension-xht" = [ defaultBrowser ];
      "video/mp4" = [ "mpv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "audio/x-wav" = [ "mpv.desktop" ];
      "application/octet-stream" = [ "mpv.desktop" ];
    };
  };
}
