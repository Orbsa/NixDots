{ pkgs, ... }:
{
  imports = [
    ./utils/leap.nix
    ./noice.nix
    ./hardmode.nix
    ./bufferline.nix
    ./cmp.nix
    ./copilot-chat.nix
    ./git.nix
    ./lightline.nix
    ./lsp/default.nix
    ./lsp/fidget.nix
    ./lsp/ionide.nix
    ./lsp/none-ls.nix
    ./lsp/trouble.nix
    ./nvim-tree.nix
    ./options.nix
    ./treesitter.nix
    ./utils/auto-pairs.nix
    ./utils/autosave.nix
    ./utils/blankline.nix
    ./utils/telescope.nix
    ./utils/toggleterm.nix
    ./utils/which-key.nix
    ./utils/wilder.nix
  ];
  programs.nixvim = {
    colorschemes.dracula.enable = true;
    plugins.neoscroll.enable = true;
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "precognition";
        src = pkgs.fetchFromGitHub {
          owner = "tris203";
          repo = "precognition.nvim";
          rev = "2a566f03eb06859298eff837f3a6686dfa5304a5";
          hash = "sha256-XLcyRB4ow5nPoQ0S29bx0utV9Z/wogg7c3rozYSqlWE=";
        };
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "nui";
        src = pkgs.fetchFromGitHub {
          owner = "MunifTanjim";
          repo = "nui.nvim";
          rev = "61574ce6e60c815b0a0c4b5655b8486ba58089a1";
          hash = "sha256-o2iNktcWxL0oCtCkbARMiWnTlZA8QWQHy2qeOanBlO4=";
        };
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "actions-preview";
        src = pkgs.fetchFromGitHub {
          owner = "aznhe21";
          repo = "actions-preview.nvim";
          rev = "9f52a01c374318e91337697ebed51c6fae57f8a4";
          hash = "sha256-lYjsv8y1fMuTGpBF/iG7cm/a7tLdh748vJhVsSp/Iz8=";
        };
      })
    ];

    extraConfigLua = ''require('actions-preview').setup {
      diff = {
        algorithm = 'patience',
        ignore_whitespace = true,
        ctxlen = 3,
      },
      backend = { 'telescope', 'nui'},
    }'';
    extraConfigVim = ''
      autocmd BufRead,BufNewFile *.pl set filetype=prolog
    '';

    globals.mapleader = " ";
    keymaps = [
      # Global
      {
        key = "<C-c>";
        action = "+y";
        options.desc = "Copy to clipboard";
      }
      {
        key = "<leader>hr";
        action = "<CMD>Hardtime report<CR>";
        options.desc = "Report hardtime";
      }
      {
        key = "<leader>la";
        action = "<CMD> lua require('actions-preview').code_actions<CR>";
        options.desc = "Code Action Menu";
      }
      # Default mode is "" which means normal-visual-op
      {
	key = "<C-n>";
	action = "<CMD>NvimTreeToggle<CR>";
	options.desc = "Toggle NvimTree";
      }
      {
	key = "<leader>c";
	action = "+context";
      }
      {
	key = "<leader>co";
	action = "<CMD>TSContextToggle<CR>";
	options.desc = "Toggle Treesitter context";
      }
      {
	key = "<leader>ct";
	action = "<CMD>CopilotChatToggle<CR>";
	options.desc = "Toggle Copilot Chat Window";
      }
      {
	key = "<leader>cf";
	action = "<CMD>CopilotChatFix<CR>";
	options.desc = "Fix the selected code";
      }
      {
	key = "<leader>cs";
	action = "<CMD>CopilotChatStop<CR>";
	options.desc = "Stop current Copilot output";
      }
      {
	key = "<leader>cr";
	action = "<CMD>CopilotChatReview<CR>";
	options.desc = "Review the selected code";
      }
      {
	key = "<leader>ce";
	action = "<CMD>CopilotChatExplain<CR>";
	options.desc = "Give an explanation for the selected code";
      }
      {
	key = "<leader>cd";
	action = "<CMD>CopilotChatDocs<CR>";
	options.desc = "Add documentation for the selection";
      }
      {
	key = "<leader>cp";
	action = "<CMD>CopilotChatTests<CR>";
	options.desc = "Add tests for my code";
      }

      # File
      {
	mode = "n";
	key = "<leader>f";
	action = "+find/file";
      }
      {
	# Format file
	key = "<leader>fm";
	action = "<CMD>lua vim.lsp.buf.format()<CR>";
	options.desc = "Format the current buffer";
      }

      # Git    
      {
	mode = "n";
	key = "<leader>g";
	action = "+git";
      }
      {
	mode = "n";
	key = "<leader>gt";
	action = "+toggles";
      }
      {
	key = "<leader>gtb";
	action = "<CMD>Gitsigns toggle_current_line_blame<CR>";
	options.desc = "Gitsigns current line blame";
      }
      {
	key = "<leader>gtd";
	action = "<CMD>Gitsigns toggle_deleted";
	options.desc = "Gitsigns deleted";
      }
      {
	key = "<leader>gd";
	action = "<CMD>Gitsigns diffthis<CR>";
	options.desc = "Gitsigns diff this buffer";
      }
      {
	mode = "n";
	key = "<leader>gr";
	action = "+resets";
      }
      {
	key = "<leader>grh";
	action = "<CMD>Gitsigns reset_hunk<CR>";
	options.desc = "Gitsigns reset hunk";
      }
      {
	key = "<leader>grb";
	action = "<CMD>Gitsigns reset_buffer<CR>";
	options.desc = "Gitsigns reset current buffer";
      }
      # Terminal
      {
	# Escape terminal mode using ESC
	mode = "t";
	key = "<esc>";
	action = "<C-\\><C-n>";
	options.desc = "Escape terminal mode";
      }

      # Trouble 
      {
	mode = "n";
	key = "<leader>d";
	action = "+diagnostics/debug";
      }
      {
	key = "<leader>dt";
	action = "<CMD>TroubleToggle<CR>";
	options.desc = "Toggle trouble";
      }
      {
	# Start standalone rust-analyzer (fixes issues when opening files from nvim tree)
	mode = "n";
	key = "<leader>rs";
	action = "<CMD>RustStartStandaloneServerForBuffer<CR>";
	options.desc = "Start standalone rust-analyzer";
      }
    ];
  };
}
