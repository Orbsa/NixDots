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
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-space";
    shell = "${pkgs.fish}/bin/fish";
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
        #{ plugin = tmux-tilit;
          #extraConfig = ''
            #set -g @tilit-navigator 'on'
            #set -g @tilit-prefix 'C-space'
            #set -g repeat-time 1000
          #'';
        #}
        {
          plugin = power-theme;
          extraConfig = ''
            set -g @tmux_power_theme 'everforest'
            set -g @tmux_power_right_arrow_icon    ''
            set -g @tmux_power_left_arrow_icon     ''
          '';
        }
        tmux-fzf
        better-mouse-mode
        vim-tmux-navigator
        extrakto
      ];
    extraConfig = ''
      version_pat='s/^tmux[^0-9]*([.0-9]+).*/\1/p'

      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind '"' split-window -c "#{pane_current_path}"
      bind '%' split-window -h -c "#{pane_current_path}"
      bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
      tmux_version="$(tmux -V | sed -En "$version_pat")"
      setenv -g tmux_version "$tmux_version"

      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi C-h select-pane -L
      bind-key -T copy-mode-vi C-j select-pane -D
      bind-key -T copy-mode-vi C-k select-pane -U
      bind-key -T copy-mode-vi C-l select-pane -R
      bind-key -T copy-mode-vi C-\\ select-pane -l

      set -g @rose_pine_variant 'main'
    '';
  };
}

