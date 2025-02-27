{ lib, pkgs, ... }: 

let 
fromGitHub = rev: ref: repo: doCheck : pkgs.vimUtils.buildVimPlugin {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
      rev = rev;
    };
    doCheck = doCheck;
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
        git-blame-nvim
        vim-surround
        neogit
        neoscroll-nvim
        typescript-tools-nvim
        (fromGitHub "c0dc939be1de00f59a49cfb96641262df760950e" "main" "cordx56/rustowl" false)
        harpoon2
        #rustaceanvim
        zephyr-nvim # theme
        nvim-treesitter-with-plugins # muh treesitter
        nvim-treesitter-textobjects# muh treesitter
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
        (fromGitHub "4b7334a09cd2434e73588cc0ea63e71177251249" "main" "sphamba/smear-cursor.nvim" true)
        nvim-web-devicons # better icons
        roslyn-nvim # C# LSP
        plenary-nvim # lib dep
        nui-nvim # lib dep
        fzf-lua # fuzzy
        vimspector # Debugger
        (fromGitHub "5b6d296eefc75331e2ff9f0adcffbd7d27862dd6" "main" "jackMort/ChatGPT.nvim" false)
        #(fromGitHub "28113b9c7d23cebe54cfc9adac36aa613096e718" "main" "frankroeder/parrot.nvim" false)
        (fromGitHub "93130e44cbc16c592081716d59905353c6a9ad10" "main" "tris203/rzls.nvim" true)
      ];
  };
}


