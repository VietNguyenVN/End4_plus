return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local lint = require("lint")
      lint.linters["markdownlint-cli2"].args = {
        "--config",
        vim.fn.expand("~/.markdownlint.yaml"),
      }
      return opts
    end,
  },
}
