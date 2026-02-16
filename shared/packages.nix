# Shared CLI packages for all systems (NixOS and Darwin)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gitui
    jujutsu
    jjui
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
