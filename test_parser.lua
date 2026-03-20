-- Test script to debug parser
-- Run with: :luafile /Users/juan/wsp/cmp-pddl/test_parser.lua

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

-- Get current buffer
local buf = vim.api.nvim_get_current_buf()
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local text = table.concat(lines, "\n")

print("Buffer number:", buf)
print("Lines read:", #lines)
print("Text length:", #text)
print("Text preview:", text:sub(1, 100))
print("")

local domain, err = parser.parse_domain(text)

if not domain then
	print("ERROR:", err)
else
	print("Domain name:", domain.name)
	print("Domain.raw length:", domain.raw and #domain.raw or "NIL")
	print("Domain.raw preview:", domain.raw and domain.raw:sub(1, 100) or "NIL")
end
