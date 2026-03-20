-- plugin/cmp_pddl.lua
-- Entry point for the cmp-pddl Neovim plugin

-- ─── Aggressive cache clearing ────────────────────────────────────────────────
-- This ensures that after :Lazy update, the fresh module code is always loaded
-- without requiring manual cache clearing by the user.

-- First, clear vim.loader bytecode cache
if vim.loader then
	vim.loader.reset()
end

-- Then, unload all cmp_pddl modules from package.loaded
-- This is critical because vim.loader.reset() alone doesn't clear already-loaded modules
local function clear_cmp_pddl_cache()
	for key, _ in pairs(package.loaded) do
		if key:match("^cmp_pddl") then
			package.loaded[key] = nil
		end
	end
end

-- Clear on initial load
clear_cmp_pddl_cache()

-- Clear cache whenever this file is sourced (e.g., after :Lazy update)
-- This autocmd ensures fresh loads even if Neovim reuses the runtime
vim.api.nvim_create_autocmd("SourcePost", {
	pattern = "*/plugin/cmp_pddl.lua",
	callback = function()
		if vim.loader then
			vim.loader.reset()
		end
		clear_cmp_pddl_cache()
	end,
})

-- ─── Register cmp source ──────────────────────────────────────────────────────

-- Register after VimEnter so nvim-cmp is loaded
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local ok, cmp = pcall(require, "cmp")
		if ok then
			cmp.register_source("pddl", require("cmp_pddl").new())
		end
	end,
})

-- ─── Register commands ────────────────────────────────────────────────────────

-- Load commands module (which defines :PddlSolve, :PddlAddServer, etc.)
require("cmp_pddl.commands").setup()

-- Development reload command
vim.api.nvim_create_user_command("PddlReload", function()
	-- Clear all cmp_pddl modules from package.loaded
	for key, _ in pairs(package.loaded) do
		if key:match("^cmp_pddl") then
			package.loaded[key] = nil
		end
	end

	-- Reset vim.loader cache
	if vim.loader then
		vim.loader.reset()
	end

	-- Reload commands
	require("cmp_pddl.commands").setup()

	vim.notify("[cmp-pddl] Reloaded all modules", vim.log.levels.INFO)
end, { desc = "Reload cmp-pddl modules (development)" })

-- Legacy :PddlParse command for backward compatibility
vim.api.nvim_create_user_command("PddlParse", function()
	local parser = require("cmp_pddl.parser")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local text = table.concat(lines, "\n")
	local ft = parser.detect_file_type(text)

	local result
	if ft == "domain" then
		result = parser.parse_domain(text)
	elseif ft == "problem" then
		result = parser.parse_problem(text)
	else
		print("Not a PDDL file")
		return
	end

	local out = vim.split(vim.inspect(result), "\n")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
	vim.cmd("split")
	vim.api.nvim_win_set_buf(0, buf)
	vim.bo[buf].filetype = "lua"
end, { desc = "Parse current PDDL buffer and show structure" })
