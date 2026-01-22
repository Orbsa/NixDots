{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    fishPlugins.done
    #fishPlugins.fzf-fish
    fishPlugins.forgit
    #fishPlugins.hydro
    #fishPlugins.grc
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    grc
  ];
  # programs.atuin = {
  #   enable = true;
  #   enableFishIntegration = true;
  #   flags = ["--disable-up-arrow"];
  #   settings = {
  #     auto_sync = true;
  #     sync_frequency = "5m";
  #     sync_address = "https://atuin.orbsa.net";
  #     key_path = "${config.home.homeDirectory}/secrets/ATUIN_KEY";
  #     ctrl_n_shortcuts = true;
  #     enter_accept = true;
  #     filter_mode = "session";
  #   };
  # };
  programs.fish = {
    enable = true;
    plugins = [
      {name = "grc"; src = pkgs.fishPlugins.grc.src; } 
      {name = "done"; src = pkgs.fishPlugins.done.src;} 
      # {name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src;} 
      # {name = "forgit"; src = pkgs.fishPlugins.forgit.src;} 
      #{name = "hydro"; src = pkgs.fishPlugins.hydro.src;} 
    ];
  };
  programs.starship = {
    enable = true;
    settings = {
      #enableFishIntegration = true;
      directory.read_only = " ";
      directory.fish_style_pwd_dir_length = 1; # turn on fish directory truncation
      directory.truncation_length = 2; # number of directories not to truncate

      gcloud.symbol = " ";
      gcloud.disabled = true; # annoying to always have on

      hostname.style = "bold green"; # don't like the default

      memory_usage.symbol = " ";
      memory_usage.disabled = true; # because it includes cached memory it's reported as full a lot

      shlvl.symbol = " ";
      shlvl.disabled = false;

      username.style_user = "bold blue"; # don't like the default
    };
  };
}

