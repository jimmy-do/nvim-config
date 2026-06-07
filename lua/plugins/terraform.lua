local function terraform_path(filename)
	return vim.fs.normalize(filename or vim.api.nvim_buf_get_name(0))
end

local function is_terraform_env(filename)
	return terraform_path(filename):find("/terraform/envs/", 1, true) ~= nil
end

local function is_terraform_module(filename)
	return terraform_path(filename):find("/terraform/modules/", 1, true) ~= nil
end

return {
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			local lint = require("lint")
			local terraform_validate = lint.linters.terraform_validate

			if type(terraform_validate) == "function" then
				terraform_validate = terraform_validate()
			end

			terraform_validate.args = {
				function()
					return "-chdir=" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
				end,
				"validate",
				"-json",
			}

			terraform_validate.condition = function(ctx)
				if is_terraform_module(ctx.filename) then
					return false
				end

				return is_terraform_env(ctx.filename)
			end

			lint.linters.terraform_validate = terraform_validate

			opts.linters_by_ft = opts.linters_by_ft or {}
			opts.linters_by_ft.terraform = { "terraform_validate" }
			opts.linters_by_ft.tf = { "terraform_validate" }
		end,
	},

	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			local terraformls = opts.servers.terraformls
			terraformls = type(terraformls) == "table" and terraformls or {}

			local on_attach = terraformls.on_attach
			terraformls.on_attach = function(client, bufnr)
				client.server_capabilities.semanticTokensProvider = nil
				if on_attach then
					return on_attach(client, bufnr)
				end
			end

			opts.servers.terraformls = terraformls
		end,
	},

	-- Prevent duplicate terraform_validate diagnostics from none-ls if it is enabled.
	-- We only want nvim-lint handling the scoped logic above.
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		opts = function(_, opts)
			local null_ls = require("null-ls")

			opts.sources = vim.tbl_filter(function(source)
				return source.name ~= null_ls.builtins.diagnostics.terraform_validate.name
			end, opts.sources or {})
		end,
	},
}
