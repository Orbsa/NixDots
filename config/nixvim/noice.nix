{
  programs.nixvim.plugins.noice = {
    enable = true;
    cmdline = {
      enabled = true;
    };
    messages = {
      enabled= true;
    };
    lsp.signature.enabled = true;
  };
  programs.nixvim.plugins.notify = {
    enable = true;
    render = "compact";
    timeout = 3000;
  };
}
