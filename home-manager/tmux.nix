{ pkgs, ... }:
let
  tmux-tilit =  pkgs.tmuxPlugins.mkTmuxPlugin
  {
    pluginName = "tmux-tilit";
    version = "unstable-2024-10-27";
    src = pkgs.fetchFromGitHub {
      owner = "2KAbhishek";
      repo = "tmux-tilit";
      rev = "0cd3a96c3f34eee057d8215112336da1448b3fa0";
      sha256 = "sha256-Q21kSGcXAPhG4Q94B/ZD38zaBojgbvsBuQi5unkpJN0=";
    };
  };
  tmux-powerline=  pkgs.tmuxPlugins.mkTmuxPlugin
  {
    pluginName = "tmux-powerline";
    version = "unstable-2024-10-19";
    src = pkgs.fetchFromGitHub {
      owner = "erikw";
      repo = "tmux-powerline";
      rev = "7a29f71563828e3093d860695d11583bd874acb4";
      sha256 = "sha256-68Jm1m0f2SYtYExk84ozRORVFzzX7e9zP/X29i6Vnc8=";
    };
  };
in
{
  programs.tmux = {
    enable = true;
    #shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    sensibleOnTop = true;
    historyLimit = 100000;
    plugins = with pkgs.tmuxPlugins;
      [
        {
          plugin = tmux-thumbs;
          extraConfig = "set -g @thumbs-key F";
        }
        {
          plugin = tmux-powerline;
          #extraConfig = "set -g @super-fingers-key f";
        }
        { plugin = tmux-tilit;
          extraConfig = "
            set -g @tilit-navigator 'on'
            set -g @tilit-prefix 'M-b'
            set -g repeat-time 1000
          ";
        }
        better-mouse-mode
      ];
    extraConfig = ''
    set-option -g default-command /nix/store/lh19r6hngpjap0qaflmx0iz0bqhggps6-fish-3.7.1/bin/fish
    '';
  };
}

