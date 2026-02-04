{ ... }: {
  homebrew = {
    enable = true;
    global = { autoUpdate = true; };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    brews = [
      "borders"
      "terminal-notifier"
      "jiratui"
      "gimme-aws-creds"
    ];
    casks = [
      "claude"
      "json-viewer"
      "mongodb-compass"
      "bruno"
      "krita"
      "orion"
      "aldente"
      "ghostty"
      "keepassxc"
      "macfuse"
      "hiddenbar"
      "dbeaver-community"
      "httpie-desktop"
      "meetingbar"
      "karabiner-elements"
      "eurkey"
      "nikitabobko/tap/aerospace"
      "alacritty"
      "tidal"
      "shottr"
      "the-unarchiver"
      "eul"
      "sf-symbols"
      "time-out"
      "raycast"
      "obsidian"
      "visual-studio-code"
      "zed"
      "linear-linear"
      "spacedrive"
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
