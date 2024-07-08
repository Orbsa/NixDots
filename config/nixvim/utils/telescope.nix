{
  programs.nixvim.plugins.telescope = {
    enable = true;
    keymaps = {
      "<leader>tg" = "live_grep";
      "<leader>tb" = "buffers";
      "<leader>tt" = "builtin";
      "<leader>tm" = "marks";
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
