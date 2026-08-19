return {
  "gnsfujiwara/suda.nvim",
  event = "VeryLazy",
  opts = {
    -- Optional overrides go here
  },
  vim.api.nvim_create_user_command("Sw", function(opts)
    vim.cmd("SudaWrite" .. (opts.args ~= "" and " " .. opts.args or ""))
  end, {
    nargs = "?",
    complete = "file",
  }),
}
