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
    withPython3 = true;
    withNodeJs = true;
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
          terraform
          rust
          zig
          html
          css
          javascript
          tsx
          typescript
          toml
          yaml
        ]);
    in
      with pkgs.vimPlugins; [
        nvim-cmp
        cmp-buffer
        cmp_luasnip
        cmp-nvim-lsp
        cmp-treesitter
        cmp-path

        flash-nvim # motion

        nvim-lspconfig # LSP helper
        luasnip
        vim-surround
        neogit
        neoscroll-nvim
        typescript-tools-nvim
        (fromGitHub "76e9331f3c4cf2cc0b634d08a2438d1b40d0e424" "main" "sphamba/smear-cursor.nvim")
        harpoon2
        rustaceanvim
        zephyr-nvim # theme
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
        # (fromGitHub "ac8c6fbb5e0e25d7841fe7ccc3c9d8ab658cad30" "main" "frankroeder/parrot.nvim")
        (fromGitHub "5b2e18681eebb7d02564c3fd62895f1c646dfafc" "main" "tris203/rzls.nvim")
      ];
  };
}


