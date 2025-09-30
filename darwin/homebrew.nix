{ ... }: {
  homebrew = {
    enable = true;
    global = { autoUpdate = true; };
    # will not be uninstalled when removed
    onActivation = {
      # "zap" removes manually installed brews and casks
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
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
      "sketchybar"
      "terminal-notifier" # Dunst on macos
      #"ios-deploy"

      # work
      "gimme-aws-creds" # AWS Okta creds
      #"libmagic"
      #"ruff" # python linter
    ];
    casks = [
      "claude"
      # utilities
      "json-viewer"
      "mongodb-compass"
      "bruno" # API Testing
      "krita" # drawing software
      "orion" # browser
      "aldente" # battery management
      "ghostty"
      #"easy-move-plus-resize" # X like resize # This doesn't keep installed for some reason
      "keepassxc"
      "macfuse" # file system utilities
      "hiddenbar" # hides menu bar icons
      "dbeaver-community" # Database manager
      "httpie" # not postman
      "meetingbar" # shows upcoming meetings
      "karabiner-elements" # keyboard remap
      "eurkey" # keyboard layout
      "nikitabobko/tap/aerospace" # tiling window manager
      #"displaylink" # connect to external dell displays
      "alacritty" # better terminal

      # coding
      #"intellij-idea"
      #"postman"
      # "dotnet" # This should be managed with local flakes

      # virtualization
      #"utm" # virtual machines
      # "docker" # docker desktop // This has issues installing here, install manually

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
      #"mpv" # media player
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
      "nikitabobko/tap" # aerospace
      "omnisharp/omnisharp-roslyn" # CSharp SDK
    ];
  };
}
