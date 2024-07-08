{
  programs.nixvim.plugins.telescope = {
    enable = true;
    keymaps = {
      "<leader>tg" = "live_grep";
      "<leader>tb" = "buffers";
      "<leader>tt" = "builtin";
      "<leader>tm" = "marks";
      "<leader>tn" = "notify";
      "<C-p>" = {
        action = "git_files";
        options = {
          desc = "Telescope Git Files";
        };
      };
    };
    extensions.fzf-native = { enable = true; };
  };
}
