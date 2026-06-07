return {
  {
    "nvzone/showkeys",
    lazy = false, -- load on startup
    opts = {
      position = "top-right",
      maxkeys = 3,
      show_count = true,
      winopts = {
        focusable = false,
        relative = "editor",
        style = "minimal",
        border = "single",
        height = 1,
        row = 1,
        col = 0,
      },
    },
    config = function(_, opts)
      require("showkeys").setup(opts)
      vim.schedule(function()
        vim.cmd("ShowkeysToggle")
      end)
    end,
  },
}
