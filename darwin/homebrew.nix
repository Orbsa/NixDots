{ ... }: {
  homebrew = {
    enable = true;
    global = { autoUpdate = true; };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    brews = [ "terminal-notifier"];
    casks = [
      "easy-move-plus-resize"
      "proxy-audio-device"
      "claude"
      "json-viewer"
      "mongodb-compass"
      "bruno"
      "orion"
      "aldente"
      "ghostty"
      #"keepassxc"
      "macfuse"
      "hiddenbar"
      "dbeaver-community"
      "httpie-desktop"
      "meetingbar"
      "karabiner-elements"
      "eurkey"
      "tidal"
      "shottr"
      "the-unarchiver"
      "eul"
      "sf-symbols"
      "time-out"
      "raycast"
      "obsidian"
      "zed"
      "linear"
      "chatgpt"
    ];
    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "FelixKratz/formulae"
      "nikitabobko/tap"
      "omnisharp/omnisharp-roslyn"
    ];
  };
}
