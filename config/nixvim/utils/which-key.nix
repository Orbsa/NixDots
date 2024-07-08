{ 
  programs.nixvim.plugins.which-key = { 
    enable = true; 
    registrations = {
      "<leader>r" = "Rust/";
      "<leader>h" = "Hardtime/";
      "<leader>t" = "Telescope/";
    };
  }; 
}
