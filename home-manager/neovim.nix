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
      nvim-lspconfig
      nvim-treesitter-with-plugins
      lualine-nvim
      lualine-lsp-progress
      which-key-nvim
      telescope-nvim
      Navigator-nvim
      nerdtree
      nerdcommenter
      mini-nvim
      nvim-web-devicons
      plenary-nvim
      fzf-lua
      #(fromGitHub "ac8c6fbb5e0e25d7841fe7ccc3c9d8ab658cad30" "main" "frankroeder/parrot.nvim")
    ];
  };
}


