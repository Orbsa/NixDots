{ pkgs, ... }:

let
  tmux-tilit = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-tilit";
    version = "unstable-2025-12-19";
    src = pkgs.fetchFromGitHub {
      owner = "2KAbhishek";
      repo = "tmux-tilit";
      rev = "29d08003b261ba3ebd3a827673674c3d839d182c";
      sha256 = "sha256-9tDSqcdROmbTpnAkpKwJjAeJcac2iF+LeBi5SBDL9Bg=";
    };
  };
in {
  programs.tmux = {
    tmuxp.enable = true;
    enable = true;
    prefix = "C-space";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    #sensibleOnTop = true; # This is causing hanging with fish in tmux
    historyLimit = 100000;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = rose-pine;
        extraConfig = ''
          set -g @rose_pine_variant 'main'
          set -g @rose_pine_hostname_short 'on'
          set -g @rose_pine_date_time '%H:%M'
          set -g @rose_pine_directory 'on'
          set -g @rose_pine_window_status_separator "  "
          set -g @rose_pine_disable_active_window_menu 'on'
          #set -g @rose_pine_session_icon " "
          #set -g @rose_pine_current_window_icon " "
          #set -g @rose_pine_folder_icon " "
          #set -g @rose_pine_username_icon " "
          set -g @rose_pine_hostname_icon '󰒋'
          set -g @rose_pine_date_time_icon '󰃰'
        '';
      }
      vim-tmux-navigator
      extrakto
    ];
    extraConfig = ''
      version_pat='s/^tmux[^0-9]*([.0-9]+).*/\1/p'
      run-shell ${tmux-tilit}/share/tmux-plugins/tmux-tilit/tilit.tmux
      set -g @tilit-navigator 'on'

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
      bind C-o display-popup -E "tms"
      bind C-j display-popup -E "tms switch"
      bind C-k display-popup -E "tms windows"
      bind C-w command-prompt -p "Rename active session to: " "run-shell 'tms rename %1'"
      bind C-r "run-shell 'tms refresh'"

      set -g @rose_pine_variant 'main'
    '';
  };
}
