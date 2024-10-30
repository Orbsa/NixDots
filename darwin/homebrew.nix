{ ... }: {
  homebrew = {
    enable = true;
    global = { autoUpdate = false; };
    # will not be uninstalled when removed
    onActivation = {
      # "zap" removes manually installed brews and casks
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
    brews = [
      #"sniffnet" # monitor network traffic
      #"aws-iam-authenticator" # eks login
      #"bitwarden-cli" # raycast extension does not like nix version
      "borders" # borders for windows
      #"openai-whisper" # transcode audio to text
      #"databricks" # databricks cli
      #"pkgxdev/made/pkgx" # run anything

      # ios development
      #"cocoapods"
      #"ios-deploy"

      # work
      #"libmagic"
      #"ruff" # python linter
    ];
    casks = [
      # utilities
      "aldente" # battery management
      "macfuse" # file system utilities
      "hiddenbar" # hides menu bar icons
      "meetingbar" # shows upcoming meetings
      "karabiner-elements" # keyboard remap
      "eurkey" # keyboard layout
      "nikitabobko/tap/aerospace" # tiling window manager
      #"displaylink" # connect to external dell displays
      "alacritty" # better terminal

      # coding
      #"intellij-idea"
      #"postman"

      # virtualization
      #"utm" # virtual machines
      "docker" # docker desktop

      # communication
      #"microsoft-teams"
      #"microsoft-auto-update"
      #"microsoft-outlook"
      #"zoom"
      #"slack"
      #"signal"
      #"discord"

      #"bitwarden" # password manager
      "tidal" # music
      #"android-studio" # needed for react-native
      #"obs" # stream / recoding software
      "shottr" # screenshot tool
      "the-unarchiver"
      "eul" # mac monitoring
      #"wireshark" # network sniffer
      "sf-symbols" # patched font for sketchybar
      "time-out" # blurs screen every x mins
      "raycast" # launcher on steroids
      #"keycastr" # show keystrokes on screen
      "obsidian" # zettelkasten
      #"arc" # mac browser
      "visual-studio-code" # code editor
      "zed" # vim like editor
      "mpv" # media player
      "linear-linear" # task management
      #"balenaetcher" # usb flashing
      "spacedrive" # file explorer
      "chatgpt" # open ai desktop client
    ];
    taps = [
      # default
      "homebrew/bundle"
      #"homebrew/cask-fonts"
      "homebrew/services"
      # custom
      "FelixKratz/formulae" # borders
      #"databricks/tap" # databricks
      #"pkgxdev/made" # pkgx
      #"nikitabobko/tap" # aerospace
    ];
  };
}
