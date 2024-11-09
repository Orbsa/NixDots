{ lib, pkgs, ... }: 

let 
fromGitHub = rev: ref: repo: pkgs.vimUtils.buildVimPlugin {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
      rev = rev;
    };
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    coc.enable = true;
    extraLuaConfig = ''
    
    dofile("/Users/ebell/.config/nvim/main.lua")
    '';
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = let
    nvim-treesitter-with-plugins = 
    pkgs.vimPlugins.nvim-treesitter.withPlugins (treesitter-plugins:
      with treesitter-plugins; [
        bash
        c
        c_sharp
        cpp
        lua
        nix
        python
        rust
        zig
        tsx
        typescript
        toml
        yaml
      ]);
  in
    with pkgs.vimPlugins; [
      zephyr-nvim # theme
      nvim-lspconfig # LSP helper
      nvim-treesitter-with-plugins # muh treesitter
      lualine-nvim # powerline
      lualine-lsp-progress 
      which-key-nvim # In case I go senile
      telescope-nvim # Pretty Menus
      dressing-nvim # opts through Telescope
      Navigator-nvim # Tmux Integration
      nvim-tree-lua # Better TreeView
      # nerdcommenter # Better comments
      oil-nvim # better 
      mini-nvim # better icons
      nvim-web-devicons # better icons
      roslyn-nvim # C# LSP
      plenary-nvim # lib dep
      fzf-lua # fuzzy
      vimspector # Debugger
      #(fromGitHub "ac8c6fbb5e0e25d7841fe7ccc3c9d8ab658cad30" "main" "frankroeder/parrot.nvim")
    ];
  };
}


