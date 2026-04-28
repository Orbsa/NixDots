# Shared CLI packages for all systems (NixOS and Darwin)
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccusage
    coreutils
    # Version control
    gnupg
    pinentry-curses
    git
    gitui
    jujutsu
    jjui
    minio-client
    gh

    # Search and navigation
    fd
    ripgrep
    fzf

    # Editors
    vim

    # TUI
    bandwhich
    btop
    csvlens
    dua
    openapi-tui
    rainfrog
    slumber
    television
    trippy

    # System tools
    fastfetch
    wget
    nix-tree
    k9s
    e1s
    tmux

    # File utilities
    lsd
    rar
    unrar

    # Media
    mpv
    yt-dlp
    ffmpeg
    mediainfo

    # Database
    sqlite
    postgresql

    # Nix tools
    comma
    nixfmt

    # Cloud/infra
    awscli2
    stu

    # Other
    parallel
  ];
}
