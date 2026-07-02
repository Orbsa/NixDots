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
      "claude"
      "ghostty"
      "raycast"
      "obsidian"
      "visual-studio-code"
      "zed"
      "linear"
      "chatgpt"
      "shottr"
      "the-unarchiver"
      "hiddenbar"
    ];
    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "FelixKratz/formulae"
    ];
  };
}
