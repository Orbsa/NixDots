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
        vim-coffee-script
        copilot-lua# You know why
        blink-cmp
        blink-copilot
        blink-cmp-git
        blink-emoji-nvim
        blink-nerdfont-nvim
        blink-ripgrep-nvim
        blink-cmp-npm-nvim
        blink-cmp-conventional-commits
        blink-pairs
        # copilot-cmp
        # nvim-cmp
        # cmp-buffer
        # cmp_luasnip
        # cmp-nvim-lsp
        # cmp-treesitter
        # cmp-path
        flash-nvim # motion
        nvim-lspconfig # LSP helper
        luasnip
        gitsigns-nvim
        vim-surround
        neogit
        neoscroll-nvim
        typescript-tools-nvim
        # (fromGitHub "aba49398eeeb0134b70d40887018b2a0e7e8b41a" "main" "cordx56/rustowl" false)
        harpoon2
        zen-mode-nvim # distraction free coding
        twilight-nvim
        todo-comments-nvim
        rustaceanvim
        zephyr-nvim # theme
        miasma-nvim # theme
        dropbar-nvim
        (fromGitHub "d53f34f42d344e69303361064d4bcb46811f7fe6" "main" "xero/evangelion.nvim" true)
        rose-pine # theme
        nvim-treesitter-with-plugins 
        nvim-treesitter-textobjects
        lualine-nvim # powerline
        lualine-lsp-progress 
        crates-nvim
        which-key-nvim # In case I go senile
        vim-fugitive
        telescope-nvim # Pretty Menus
        telescope-file-browser-nvim 
        telescope-git-conflicts-nvim
        telescope-dap-nvim
        (fromGitHub "e7d495319f2a04df96402057a6992ea970f8914d" "master" "isak102/telescope-git-file-history.nvim" true)
        nvim-dap
        nvim-dap-ui
        dressing-nvim # opts through Telescope
        Navigator-nvim # Tmux Integration
        nvim-tree-lua # Better TreeView
        # nerdcommenter # Better comments
        oil-nvim # better 
        mini-nvim # better icons
        smear-cursor-nvim
        (fromGitHub "47e5ba89f71b9e6c72eaaaaa519dd59bd6897df4" "main" "dmmulroy/ts-error-translator.nvim" true)
        nvim-web-devicons # better icons
        roslyn-nvim # C# LSP
        plenary-nvim # lib dep
        nui-nvim # lib dep
        fzf-lua # fuzzy
        rzls-nvim
      ];
  };
}


