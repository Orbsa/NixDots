{ lib, pkgs, pkgs-unstable, ... }: 

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
        # (fromGitHub "aba49398eeeb0134b70d40887018b2a0e7e8b41a" "main" "cordx56/rustowl" false)
        # cmp-buffer
        # cmp-nvim-lsp
        # cmp-path
        # cmp-treesitter
        # cmp_luasnip
        # copilot-cmp
        # nerdcommenter # Better comments
        # nvim-cmp
        (fromGitHub "558abff11b9e8f4cefc0de09df780c56841c7a4b" "main" "dmmulroy/ts-error-translator.nvim" true)
        (fromGitHub "d53f34f42d344e69303361064d4bcb46811f7fe6" "main" "xero/evangelion.nvim" true)
        (fromGitHub "e7d495319f2a04df96402057a6992ea970f8914d" "master" "isak102/telescope-git-file-history.nvim" true)
        blink-cmp
        blink-cmp-conventional-commits
        blink-cmp-git
        blink-cmp-npm-nvim
        blink-copilot
        blink-emoji-nvim
        blink-nerdfont-nvim
        blink-pairs
        blink-ripgrep-nvim
        pkgs-unstable.vimPlugins.codediff-nvim
        copilot-lua# You know why
        crates-nvim
        dressing-nvim # opts through Telescope
        dropbar-nvim
        flash-nvim # motion
        fzf-lua # fuzzy
        gitsigns-nvim
        harpoon2
        lualine-lsp-progress 
        lualine-nvim # powerline
        luasnip
        miasma-nvim # theme
        mini-nvim # better icons
        Navigator-nvim # Tmux Integration
        neogit
        neoscroll-nvim
        nui-nvim # lib dep
        nvim-dap
        nvim-dap-ui
        nvim-lspconfig # LSP helper
        nvim-tree-lua # Better TreeView
        nvim-treesitter-textobjects
        nvim-treesitter-with-plugins 
        nvim-web-devicons # better icons
        oil-nvim # better 
        plenary-nvim # lib dep
        rose-pine # theme
        roslyn-nvim # C# LSP
        rustaceanvim
        rzls-nvim
        smear-cursor-nvim
        telescope-dap-nvim
        telescope-file-browser-nvim 
        telescope-git-conflicts-nvim
        telescope-nvim # Pretty Menus
        todo-comments-nvim
        twilight-nvim
        typescript-tools-nvim
        vim-coffee-script
        vim-fugitive
        vim-surround
        which-key-nvim # In case I go senile
        zen-mode-nvim # distraction free coding
        zephyr-nvim # theme
      ];
  };
}


