{ pkgs, lib, config, inputs, ... }:

{
  home.packages = with pkgs; [
    inputs.rind.packages.${pkgs.system}.default
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.grc
    fishPlugins.z
    ripgrep
    yazi
    jq
    yq-go
    eza
    fzf
    grc
  ];

  programs.atuin = {
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
    loginShellInit = ''
      if uwsm check may-start
        exec uwsm start hyprland.desktop
      end
    '';
    interactiveShellInit = ''
      if not contains /run/current-system/sw/share $XDG_DATA_DIRS
        set -gx XDG_DATA_DIRS /run/current-system/sw/share /home/eric/.nix-profile/share /etc/profiles/per-user/eric/share $XDG_DATA_DIRS
      end
    '';
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
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$username"
        "$directory"
        "$nix_shell"
        "$git_branch"
        "$git_status"
        "$fill"
        "$c"
        "$elixir"
        "$elm"
        "$golang"
        "$haskell"
        "$java"
        "$julia"
        "$nodejs"
        "$nim"
        "$rust"
        "$scala"
        "$conda"
        "$python"
        "$time"
        "\n"
        "[󱞪](fg:iris) "
      ];

      palette = "rose-pine";

      palettes.rose-pine = {
        overlay = "#26233a";
        love = "#eb6f92";
        gold = "#f6c177";
        rose = "#ebbcba";
        pine = "#31748f";
        foam = "#9ccfd8";
        iris = "#c4a7e7";
      };

      directory = {
        format = "[](fg:overlay)[ $path ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:pine";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      fill = {
        style = "fg:overlay";
        symbol = " ";
      };

      git_branch = {
        format = "[](fg:overlay)[ $symbol $branch ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:foam";
        symbol = "";
      };

      git_status = {
        disabled = false;
        style = "bg:overlay fg:love";
        format = "[](fg:overlay)([$all_status$ahead_behind]($style))[](fg:overlay) ";
        up_to_date = "[ ✓ ](bg:overlay fg:iris)";
        untracked = "[?($count)](bg:overlay fg:gold)";
        stashed = "[\\$](bg:overlay fg:iris)";
        modified = "[!($count)](bg:overlay fg:gold)";
        renamed = "[»($count)](bg:overlay fg:iris)";
        deleted = "[✘($count)](style)";
        staged = "[++($count)](bg:overlay fg:gold)";
        ahead = "[⇡(\${count})](bg:overlay fg:foam)";
        diverged = "⇕[\\[](bg:overlay fg:iris)[⇡(\${ahead_count})](bg:overlay fg:foam)[⇣(\${behind_count})](bg:overlay fg:rose)[\\]](bg:overlay fg:iris)";
        behind = "[⇣(\${count})](bg:overlay fg:rose)";
      };

      time = {
        disabled = false;
        format = " [](fg:overlay)[ $time 󰴈 ]($style)[](fg:overlay)";
        style = "bg:overlay fg:rose";
        time_format = "%I:%M%P";
        use_12hr = true;
      };

      username = {
        disabled = true;
        format = "[](fg:overlay)[ 󰧱 $user ]($style)[](fg:overlay) ";
        show_always = true;
        style_root = "bg:overlay fg:iris";
        style_user = "bg:overlay fg:iris";
      };

      nix_shell = {
        disabled = false;
        format = "[](fg:overlay)[ 󱄅 $state ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:foam";
        impure_msg = "[impure](bg:overlay fg:rose)";
        pure_msg = "[pure](bg:iris fg:rose)";
        unknown_msg = "[unknown](bg:gold fg:rose)";
      };

      aws.symbol = "";
      conda.symbol = "";
      dart.symbol = "";
      docker_context.symbol = "";
      elixir.symbol = "";
      elm.symbol = "";
      golang.symbol = "󰟓";
      java.symbol = "";
      julia.symbol = "";
      lua.symbol = "󰢱 ";
      nim.symbol = "";
      nix_shell.symbol = "󱄅";
      nodejs.symbol = "";
      package.symbol = "󰏗 ";
      perl.symbol = "";
      php.symbol = "";
      python.symbol = "";
      ruby.symbol = "";
      rust.symbol = "󱘗 ";
      scala.symbol = "";
      swift.symbol = "";
      terraform.symbol = "󱁢 ";
      bun.symbol = "🥟";
    };
  };
}
