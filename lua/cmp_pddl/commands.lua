-- lua/cmp_pddl/commands.lua
-- Defines all :Pddl* user commands.

local M = {}

function M.setup()
	local parser = require("cmp_pddl.parser")
	local solver = require("cmp_pddl.solver")

	-- ── :PddlParse ─────────────────────────────────────────────────────────────
	vim.api.nvim_create_user_command("PddlParse", function()
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local text = table.concat(lines, "\n")
		local ft = parser.detect_file_type(text)
		local result, err

		if ft == "domain" then
			result, err = parser.parse_domain(text)
		elseif ft == "problem" then
			result, err = parser.parse_problem(text)
		else
			vim.notify("[cmp-pddl] Not a PDDL domain or problem file", vim.log.levels.WARN)
			return
		end

		if err then
			vim.notify("[cmp-pddl] Parse error: " .. err, vim.log.levels.ERROR)
			return
		end

		local out = vim.split(vim.inspect(result), "\n")
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
		vim.bo[buf].filetype = "lua"
		vim.bo[buf].buftype = "nofile"
		vim.cmd("botright split")
		vim.api.nvim_win_set_buf(0, buf)
		vim.api.nvim_win_set_height(0, 20)
		vim.keymap.set("n", "q", ":bd<CR>", { buffer = buf, silent = true })
	end, { desc = "Parse current PDDL buffer and show structure" })

	-- ── :PddlSolve ─────────────────────────────────────────────────────────────
	vim.api.nvim_create_user_command("PddlSolve", function()
		M._pick_domain_and_problem(function(domain_buf, problem_buf)
			if not domain_buf or not problem_buf then
				return
			end

			-- Get file paths
			local domain_path = vim.api.nvim_buf_get_name(domain_buf)
			local problem_path = vim.api.nvim_buf_get_name(problem_buf)

			local d_text = table.concat(vim.api.nvim_buf_get_lines(domain_buf, 0, -1, false), "\n")
			local p_text = table.concat(vim.api.nvim_buf_get_lines(problem_buf, 0, -1, false), "\n")

			local domain, derr = parser.parse_domain(d_text)
			local problem, perr = parser.parse_problem(p_text)

			if not domain then
				vim.notify("[cmp-pddl] Domain parse error: " .. (derr or "?"), vim.log.levels.ERROR)
				return
			end
			if not problem then
				vim.notify("[cmp-pddl] Problem parse error: " .. (perr or "?"), vim.log.levels.ERROR)
				return
			end

			-- Validation is advisory only — user explicitly chose the files
			local val = parser.validate(domain, problem)
			for _, w in ipairs(val.warnings) do
				vim.notify("[cmp-pddl] ⚠ " .. w, vim.log.levels.WARN)
			end
			for _, e in ipairs(val.errors) do
				vim.notify("[cmp-pddl] ⚠ " .. e, vim.log.levels.WARN)
			end

			M._pick_server(function(server)
				if not server then
					return
				end
				M._pick_planner(server, function(planner)
					if not planner then
						return
					end
					solver.solve(server, planner, domain.raw, problem.raw, domain_path, problem_path)
				end)
			end)
		end)
	end, { desc = "Send domain+problem to a PDDL solver and show the plan" })

	-- ── :PddlAddServer ─────────────────────────────────────────────────────────
	vim.api.nvim_create_user_command("PddlAddServer", function()
		M._prompt_new_server(function() end)
	end, { desc = "Add a PDDL solver server URL" })

	-- ── :PddlServers ───────────────────────────────────────────────────────────
	vim.api.nvim_create_user_command("PddlServers", function()
		local servers = solver.get_servers()
		if #servers == 0 then
			vim.notify("[cmp-pddl] No servers saved. Use :PddlAddServer", vim.log.levels.INFO)
			return
		end
		local lines = { "", "  Saved PDDL solver servers:", "" }
		for i, s in ipairs(servers) do
			table.insert(lines, string.format("  [%d]  %-24s  %s", i, s.name, s.url))
		end
		table.insert(lines, "")
		table.insert(lines, "  :PddlAddServer to add more  |  :PddlSolve to run")
		table.insert(lines, "")
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].buftype = "nofile"
		vim.cmd("botright split")
		vim.api.nvim_win_set_buf(0, buf)
		vim.api.nvim_win_set_height(0, #lines + 2)
		vim.keymap.set("n", "q", ":bd<CR>", { buffer = buf, silent = true })
	end, { desc = "List saved PDDL solver servers" })
end

-- ─── PDDL file discovery ──────────────────────────────────────────────────────

--- Parse a file on disk and return its type + pddl name without loading it as a buffer.
---@param path string
---@return "domain"|"problem"|"unknown", string  ft, pddl_name
local function inspect_file(path)
	local parser = require("cmp_pddl.parser")
	local f = io.open(path, "r")
	if not f then
		return "unknown", ""
	end
	local text = f:read("*a")
	f:close()
	local ft = parser.detect_file_type(text)
	if ft == "domain" then
		local d = parser.parse_domain(text)
		return "domain", d.name
	elseif ft == "problem" then
		local p = parser.parse_problem(text)
		return "problem", p.name
	end
	return "unknown", ""
end

--- Collect all open PDDL buffers, grouped by type.
---@return {buf:integer, path:string, label:string, ft:"domain"|"problem", pddl_name:string}[]
local function open_pddl_buffers()
	local parser = require("cmp_pddl.parser")
	local result = {}
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		local path = vim.api.nvim_buf_get_name(b)
		if vim.api.nvim_buf_is_loaded(b) and (vim.bo[b].filetype == "pddl" or path:match("%.pddl$")) and path ~= "" then
			local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
			local text = table.concat(lines, "\n")
			local ft = parser.detect_file_type(text)
			if ft ~= "unknown" then
				local pddl_name = ""
				if ft == "domain" then
					pddl_name = parser.parse_domain(text).name
				else
					pddl_name = parser.parse_problem(text).name
				end
				local fname = vim.fn.fnamemodify(path, ":t")
				local label = string.format("[%-7s]  %-28s  %s", ft, pddl_name, fname)
				table.insert(result, {
					buf = b,
					path = path,
					label = label,
					ft = ft,
					pddl_name = pddl_name,
				})
			end
		end
	end
	return result
end

--- Scan a directory for .pddl files that are NOT already open as buffers.
---@param dir string
---@param exclude_paths table<string,boolean>
---@return {path:string, label:string, ft:"domain"|"problem", pddl_name:string}[]
local function scan_dir_for_pddl(dir, exclude_paths)
	local found = {}
	local handle = vim.loop.fs_scandir(dir)
	if not handle then
		return found
	end
	while true do
		local name, typ = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end
		if (typ == "file" or typ == "link") and name:match("%.pddl$") then
			local path = dir .. "/" .. name
			if not exclude_paths[path] then
				local ft, pddl_name = inspect_file(path)
				if ft ~= "unknown" then
					local label = string.format("[%-7s]  %-28s  %s", ft, pddl_name, name)
					table.insert(found, { path = path, label = label, ft = ft, pddl_name = pddl_name })
				end
			end
		end
	end
	return found
end

--- Load a file into a buffer and return the buffer number.
---@param path string
---@return integer
local function load_file(path)
	-- Check if already loaded
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(b) == path then
			return b
		end
	end
	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)
	vim.bo[buf].filetype = "pddl"
	return buf
end

-- ─── Domain + Problem picker ──────────────────────────────────────────────────

--- Smart picker:
---   • Lists all open PDDL buffers
---   • Also scans the current file's directory for .pddl files not yet open
---   • If exactly one domain + one problem exist → use them directly, no prompt
---   • If multiple options → prompt user to pick
---@param on_done fun(domain_buf:integer|nil, problem_buf:integer|nil)
function M._pick_domain_and_problem(on_done)
	-- Gather open buffers
	local open_bufs = open_pddl_buffers()
	local open_paths = {}
	for _, b in ipairs(open_bufs) do
		open_paths[b.path] = true
	end

	-- Scan the directory of the current buffer for additional .pddl files
	local cur_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
	local dir_files = scan_dir_for_pddl(cur_dir, open_paths)

	-- Build combined candidate list  (open buffers first, then disk files)
	local domains, problems = {}, {}

	for _, b in ipairs(open_bufs) do
		if b.ft == "domain" then
			table.insert(domains, { buf = b.buf, label = b.label, path = b.path })
		end
		if b.ft == "problem" then
			table.insert(problems, { buf = b.buf, label = b.label, path = b.path })
		end
	end
	for _, f in ipairs(dir_files) do
		local label = f.label .. "  📂" -- mark as "from disk, not yet open"
		if f.ft == "domain" then
			table.insert(domains, { buf = nil, label = label, path = f.path })
		end
		if f.ft == "problem" then
			table.insert(problems, { buf = nil, label = label, path = f.path })
		end
	end

	if #domains == 0 then
		vim.notify("[cmp-pddl] No PDDL domain file found. Open or create a domain.pddl.", vim.log.levels.ERROR)
		on_done(nil, nil)
		return
	end
	if #problems == 0 then
		vim.notify("[cmp-pddl] No PDDL problem file found. Open or create a problem.pddl.", vim.log.levels.ERROR)
		on_done(nil, nil)
		return
	end

	-- Resolve a candidate to a buffer (loading from disk if needed)
	local function resolve(candidate)
		if candidate.buf then
			return candidate.buf
		end
		return load_file(candidate.path)
	end

	-- If exactly one of each → skip the prompt entirely
	if #domains == 1 and #problems == 1 then
		local db = resolve(domains[1])
		local pb = resolve(problems[1])
		vim.notify(
			"[cmp-pddl] Using: "
				.. vim.fn.fnamemodify(domains[1].path, ":t")
				.. " + "
				.. vim.fn.fnamemodify(problems[1].path, ":t"),
			vim.log.levels.INFO
		)
		on_done(db, pb)
		return
	end

	-- Multiple options → ask user
	local d_labels = vim.tbl_map(function(x)
		return x.label
	end, domains)
	vim.ui.select(d_labels, { prompt = "Select DOMAIN file:" }, function(_, d_idx)
		if not d_idx then
			on_done(nil, nil)
			return
		end

		local p_labels = vim.tbl_map(function(x)
			return x.label
		end, problems)
		vim.ui.select(p_labels, { prompt = "Select PROBLEM file:" }, function(_, p_idx)
			if not p_idx then
				on_done(nil, nil)
				return
			end
			on_done(resolve(domains[d_idx]), resolve(problems[p_idx]))
		end)
	end)
end

-- ─── Server picker ────────────────────────────────────────────────────────────

function M._pick_server(on_done)
	local solver = require("cmp_pddl.solver")
	local servers = solver.get_servers()
	local last_server, _ = solver.get_last()

	-- If no servers saved yet, go straight to add-new
	if #servers == 0 then
		vim.notify("[cmp-pddl] No servers configured. Add one now.", vim.log.levels.INFO)
		M._prompt_new_server(function(url)
			if url then
				on_done(url)
			end
		end)
		return
	end

	local items = {}
	local item_map = {}
	for _, s in ipairs(servers) do
		local label = string.format("%-24s  %s", s.name, s.url)
		if s.url == last_server then
			label = "★ " .. label
		end
		table.insert(items, label)
		item_map[label] = s.url
	end
	table.insert(items, "+ Add new server…")

	vim.ui.select(items, { prompt = "Select solver server:" }, function(choice)
		if not choice then
			on_done(nil)
			return
		end
		if choice == "+ Add new server…" then
			M._prompt_new_server(function(url)
				if url then
					on_done(url)
				end
			end)
		else
			on_done(item_map[choice])
		end
	end)
end

-- ─── New server prompt ────────────────────────────────────────────────────────

function M._prompt_new_server(on_done)
	local solver = require("cmp_pddl.solver")
	vim.ui.input({
		prompt = "Server URL: ",
		default = "https://solver.planning.domains:5001",
	}, function(url)
		if not url or url == "" then
			on_done(nil)
			return
		end
		url = url:gsub("/$", "")
		vim.ui.input({
			prompt = "Friendly name: ",
			default = url:match("//([^:/]+)") or "solver",
		}, function(name)
			if not name or name == "" then
				name = url
			end
			solver.add_server(url, name)
			vim.notify("[cmp-pddl] Saved: " .. name .. " → " .. url, vim.log.levels.INFO)
			on_done(url)
		end)
	end)
end

-- ─── Planner picker ───────────────────────────────────────────────────────────

function M._pick_planner(server, on_done)
	local solver = require("cmp_pddl.solver")
	local _, last_planner = solver.get_last()

	vim.notify("[cmp-pddl] Fetching planners …", vim.log.levels.INFO)

	solver.fetch_planners(server, function(planners, err)
		vim.schedule(function()
			if err or not planners or #planners == 0 then
				vim.notify(
					"[cmp-pddl] Could not fetch planner list"
						.. (err and (": " .. err) or "")
						.. " — enter name manually.",
					vim.log.levels.WARN
				)
				vim.ui.input({
					prompt = "Planner name (e.g. lama-first): ",
					default = last_planner or "lama-first",
				}, function(p)
					if p and p ~= "" then
						on_done(p)
					end
				end)
				return
			end

			local items = {}
			local item_map = {}
			for _, p in ipairs(planners) do
				local label = p.description ~= "" and string.format("%-30s  %s", p.id, p.description) or p.id
				if p.id == last_planner then
					label = "★ " .. label
				end
				table.insert(items, label)
				item_map[label] = p.id
			end

			vim.ui.select(items, { prompt = "Select planner  (" .. #items .. " available):" }, function(choice)
				if not choice then
					on_done(nil)
					return
				end
				on_done(item_map[choice])
			end)
		end)
	end)
end

return M
