
local xml2lua = require "xml2lua.xml2lua"
local handler = require "xml2lua.xmlhandler.tree"

local path = ...

print("begin parse:", path)

local function read_xml(path)
  local f = io.open(path, "r")
  local t = f:read("*a")
  f:close()


  local parser = xml2lua.parser(handler)
  parser:parse(t)
  return parser
end

local function parse_points(str_points)
  local str=string.format("return {%s}",string.gsub(str_points, "^%s+", ""):gsub(" ",","))
  return load(str)()
end

local function bounds(group)
  local minx, maxx
  local miny, maxy
  for _, v in ipairs(group.polyline) do
    local str_points = v._attr.points
    local points = parse_points(str_points)
    for k=1, #points, 2 do
      local x = points[k]
      if not minx and not maxx then
        minx, maxx = x, x
      elseif x < minx then
        minx = x
      elseif x > maxx then
        maxx = x
      end
    end
    for k=2, #points, 2 do
      local y = points[k]
      if not miny and not maxy then
        miny, maxy = y, y
      elseif y < miny then
        miny = y
      elseif y > maxy then
        maxy = y
      end
    end
  end
  return minx, maxx, miny, maxy
end

local function split_svg(parser)
  local root = parser.handler.root
  local g = parser.handler.root.svg.g

  print("g count:", #g)
  for k, v in ipairs(g) do
      local id = v._attr.id
      local minx, maxx, miny, maxy = bounds(v)
      print(id, minx, maxx, miny, maxy)

      root.svg.g = {v}
      local t = xml2lua.toXml(root, "", 0)
      local f = io.open("example/chunks/"..tostring(id)..".svg", "w")
      f:write(t)
      f:close()
  end
end

local parser = read_xml(path)
split_svg(parser)
