-- Test solve command that bypasses all caching
-- Run with: :luafile /Users/juan/wsp/cmp-pddl/test_solve.lua

-- Force clear cache
for k, _ in pairs(package.loaded) do
	if k:match("^cmp_pddl") then
		package.loaded[k] = nil
	end
end
if vim.loader then
	vim.loader.reset()
end

local parser = require("cmp_pddl.parser")
local solver = require("cmp_pddl.solver")

-- Find domain and problem buffers manually
local domain_buf, problem_buf, domain_path, problem_path

for _, b in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(b) then
		local lines = vim.api.nvim_buf_get_lines(b, 0, 50, false)
		local text = table.concat(lines, "\n")

		if text:match("%(define%s*%(domain") then
			domain_buf = b
			domain_path = vim.api.nvim_buf_get_name(b)
			print("Found domain buffer:", b, "path:", domain_path)
		elseif text:match("%(define%s*%(problem") then
			problem_buf = b
			problem_path = vim.api.nvim_buf_get_name(b)
			print("Found problem buffer:", b, "path:", problem_path)
		end
	end
end

if not domain_buf then
	print("ERROR: No domain buffer found!")
	return
end

if not problem_buf then
	print("ERROR: No problem buffer found!")
	return
end

-- Read buffers
local d_text = table.concat(vim.api.nvim_buf_get_lines(domain_buf, 0, -1, false), "\n")
local p_text = table.concat(vim.api.nvim_buf_get_lines(problem_buf, 0, -1, false), "\n")

print("Domain text length:", #d_text)
print("Problem text length:", #p_text)

-- Parse
local domain = parser.parse_domain(d_text)
local problem = parser.parse_problem(p_text)

print("domain.raw length:", domain.raw and #domain.raw or "NIL")
print("problem.raw length:", problem.raw and #problem.raw or "NIL")

if not domain.raw or #domain.raw == 0 then
	print("ERROR: domain.raw is empty!")
	return
end

if not problem.raw or #problem.raw == 0 then
	print("ERROR: problem.raw is empty!")
	return
end

-- Solve
print("Calling solver.solve()...")
print("Domain path:", domain_path)
print("Problem path:", problem_path)
solver.solve(
	"https://solver.planning.domains:5001",
	"dual-bfws-ffparser",
	domain.raw,
	problem.raw,
	domain_path,
	problem_path
)
