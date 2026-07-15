{ ... }: {
  homebrew = {
    enable = true;
    global = { autoUpdate = true; };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    brews = [ "terminal-notifier" "gimme-aws-creds" ];
    casks = [
      "ghostty"
      "raycast"
      "obsidian"
      "visual-studio-code"
      "discord"
      "dbeaver-community"
      "easy-move+resize"
      "linear"
      "tidal"
      "shottr"
      "the-unarchiver"
      "hiddenbar"
    ];
    taps = [
      "FelixKratz/formulae"
    ];
  };
}
