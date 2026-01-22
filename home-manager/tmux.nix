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
    #sensibleOnTop = true; # This is causing hanging with fish in tmux
    historyLimit = 100000;
    plugins = with pkgs.tmuxPlugins;
      [
        #{
          #plugin = tmux-thumbs;
          #extraConfig = "set -g @thumbs-key F";
        #}
        #{ plugin = tmux-tilit;
          #extraConfig = ''
            #set -g @tilit-navigator 'on'
            #set -g @tilit-prefix 'C-space'
            #set -g repeat-time 1000
          #'';
        #}
        # {
        #   plugin = power-theme;
        #   extraConfig = ''
        #     set -g @tmux_power_theme 'everforest'
        #     set -g @tmux_power_right_arrow_icon    ''
        #     set -g @tmux_power_left_arrow_icon     ''
        #   '';
        # }
        { 
          plugin = rose-pine;
          extraConfig = ''
            set -g @rose_pine_variant 'main'
            set -g @rose_pine_hostname_short 'on' # Makes the hostname shorter by using tmux's '#h' format
            set -g @rose_pine_date_time '%H:%M' # It accepts the date UNIX command format (man date for info)

            # set -g @rose_pine_user 'on' # Turn on the username component in the statusbar
            set -g @rose_pine_directory 'on' # Turn on the current folder component in the status bar

            # set -g @rose_pine_bar_bg_disable 'on' # Disables background color, for transparent terminal emulators
            # If @rose_pine_bar_bg_disable is set to 'on', uses the provided value to set the background color
            # It can be any of the on tmux (named colors, 256-color set, `default` or hex colors)
            # See more on http://man.openbsd.org/OpenBSD-current/man1/tmux.1#STYLES
            # set -g @rose_pine_bar_bg_disabled_color_option 'default'

            # Some of these are mutually exclusive, recommended to test which one you like
            # set -g @rose_pine_only_windows 'on' # Leaves only the window module, for max focus and space
            set -g @rose_pine_window_status_separator "  " # Changes the default icon that appears between window names
            set -g @rose_pine_disable_active_window_menu 'on' # Disables the menu that shows the active window on the left
            #set -g @rose_pine_default_window_behavior 'on' # Forces tmux default window list behaviour

            #set -g @rose_pine_show_current_program 'on' # Forces tmux to show the current running program as window name
            #set -g @rose_pine_show_pane_directory 'on' # Forces tmux to show the current directory as window name
            # Previously set -g @rose_pine_window_tabs_enabled

            # Example values for these can be:
            #set -g @rose_pine_left_separator ' > ' # The strings to use as separators are 1-space padded
            #set -g @rose_pine_right_separator ' < ' # Accepts both normal chars & nerdfont icons
            #set -g @rose_pine_field_separator '  ' # Default is two-space-padded, but can be set to anything
            #set -g @rose_pine_window_separator ' - ' # Replaces the default `:` between the window number and name

            # These are not padded
            set -g @rose_pine_session_icon '' # Changes the default icon to the left of the session name
            set -g @rose_pine_current_window_icon '' # Changes the default icon to the left of the active window name
            set -g @rose_pine_folder_icon '' # Changes the default icon to the left of the current directory folder
            set -g @rose_pine_username_icon '' # Changes the default icon to the right of the hostname
            set -g @rose_pine_hostname_icon '󰒋' # Changes the default icon to the right of the hostname
            set -g @rose_pine_date_time_icon '󰃰' # Changes the default icon to the right of the date module

            # Very beta and specific opt-in settings, tested on v3.2a, look at issue #10
            #set -g @rose_pine_prioritize_windows 'on' # Disables the right side functionality in a certain window count / terminal width
            #set -g @rose_pine_width_to_hide '80' # Specify a terminal width to toggle off most of the right side functionality
            #set -g @rose_pine_window_count '5' # Specify a number of windows, if there are more than the number, do the same as width_to_hide
          '';
        }
        #tmux-fzf
        #better-mouse-mode
        vim-tmux-navigator
        #extrakto
      ];

      #set-option -g default-command /nix/store/lh19r6hngpjap0qaflmx0iz0bqhggps6-fish-3.7.1/bin/fish
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
      bind C-o display-popup -E "tms"
      bind C-j display-popup -E "tms switch"
      bind C-k display-popup -E "tms windows"
      bind C-w command-prompt -p "Rename active session to: " "run-shell 'tms rename %1'"
      bind C-r "run-shell 'tms refresh'"

      set -g @rose_pine_variant 'main'
    '';
  };
}

