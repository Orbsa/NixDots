# Shared CLI packages for all systems (NixOS and Darwin)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Version control
    git
    jujutsu
    jjui
    gh

    # Search and navigation
    fd
    ripgrep
    fzf

    # Editors
    vim

    # System tools
    btop
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
    nixfmt-rfc-style

    # Cloud/infra
    awscli2
    stu

    # Other
    parallel
  ];
}
