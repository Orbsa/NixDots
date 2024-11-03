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
      which-key-nvim
      telescope-nvim

      # (fromGitHub "6422c3a651c3788881d01556cb2a90bdff7bf002" "master" "Shopify/shadowenv.vim")
    ];
  };
}


