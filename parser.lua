
local xml2lua = require "xml2lua.xml2lua"
local handler = require "xml2lua.xmlhandler.tree"

local path = ...

print("begin parse:", path)

local f = io.open(path, "r")
local t = f:read("*a")
f:close()


local parser = xml2lua.parser(handler)
parser:parse(t)

local root = parser.handler.root
local g = parser.handler.root.svg.g

for k, v in ipairs(g) do
    root.svg.g = {v}
    local t = xml2lua.toXml(root, "", 0)
    local f = io.open("example/chunks/"..tostring(k)..".svg", "w")
    f:write(t)
    f:close()
end
