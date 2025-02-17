{...}: {
  vim.filetree = {
    neo-tree = {
      enable = true;
      setupOpts = {
        auto_clean_after_session_restore = true;
        hide_root_node = true;
      };
    };
  };
}
