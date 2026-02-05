{ pkgs, lib, config, ... }:

{
  home.packages = with pkgs; [
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    ripgrep
    jq
    yq-go
    eza
    fzf
    grc
  ];

  programs.atuin = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.orbsa.net";
      key_path = "${config.home.homeDirectory}/secrets/ATUIN_KEY";
      ctrl_n_shortcuts = true;
      enter_accept = true;
      filter_mode = "session";
    };
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
    ];
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
      cmd_duration.disabled = true;

      format = ''
        $directory
        $character'';
      right_format = "$time";

      character = {
        success_symbol = "[](green)";
        error_symbol = "[](red)";
        vimcmd_symbol = "[](teal)";
      };

      directory = {
        format = "[$path]($style)( [$read_only]($read_only_style)) ";
        style = "blue";
        disabled = false;
        read_only = " ";
        fish_style_pwd_dir_length = 1;
        truncation_length = 2;
      };

      time = {
        format = "[$time]($style)";
        style = "blue";
        disabled = false;
      };

      status = {
        format = "[$symbol]($style)";
        symbol = "[](red)";
        success_symbol = "[](green)";
        disabled = true;
      };

      git_branch = {
        style = "purple";
        symbol = "";
      };

      gcloud.symbol = " ";
      gcloud.disabled = true;
      hostname.style = "bold green";
      memory_usage.symbol = " ";
      memory_usage.disabled = true;
      shlvl.symbol = " ";
      shlvl.disabled = false;
      username.style_user = "bold blue";

      aws.symbol = "  ";
      conda.symbol = " ";
      dart.symbol = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      golang.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      lua.symbol = " ";
      nim.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      package.symbol = " ";
      perl.symbol = " ";
      php.symbol = " ";
      python.symbol = " ";
      ruby.symbol = " ";
      rust.symbol = " ";
      scala.symbol = " ";
      swift.symbol = "ﯣ ";
      terraform.symbol = "行 ";
    };
  };
}
