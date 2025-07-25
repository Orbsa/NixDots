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
    extraLuaConfig = ''
	  dofile(os.getenv("HOME") .. "/.config/nvim/import.lua")
	  vim.g.sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}'
	'';
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
        vim-coffee-script
        copilot-lua
        copilot-cmp
        nvim-cmp
        nvim-neoclip-lua
        cmp-buffer
        cmp_luasnip
        cmp-nvim-lsp
        cmp-treesitter
        cmp-path

        flash-nvim
        nvim-lspconfig
        luasnip
        git-blame-nvim
        gitsigns-nvim
        vim-surround
        neogit
        neoscroll-nvim
        typescript-tools-nvim
        (fromGitHub "c0dc939be1de00f59a49cfb96641262df760950e" "main" "cordx56/rustowl" false)
        harpoon2
        zen-mode-nvim
        twilight-nvim
        todo-comments-nvim
        zephyr-nvim
        miasma-nvim
        (fromGitHub "d53f34f42d344e69303361064d4bcb46811f7fe6" "main" "xero/evangelion.nvim" true)
        rose-pine
        nvim-treesitter-with-plugins 
        nvim-treesitter-textobjects
        lualine-nvim
        lualine-lsp-progress 
        which-key-nvim
        telescope-nvim
        dressing-nvim
        Navigator-nvim
        nvim-tree-lua
        oil-nvim
        mini-nvim
        (fromGitHub "4b7334a09cd2434e73588cc0ea63e71177251249" "main" "sphamba/smear-cursor.nvim" true)
        nvim-web-devicons
        roslyn-nvim
        plenary-nvim
        nui-nvim
        fzf-lua
        vimspector
        (fromGitHub "93130e44cbc16c592081716d59905353c6a9ad10" "main" "tris203/rzls.nvim" true)
        # sqlite-lua with custom config
        sqlite-lua
      ];
  };
}
