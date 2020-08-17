
local xml2lua = require "xml2lua.xml2lua"
local handler = require "xml2lua.xmlhandler.tree"
local json = require "json"

local function split(str, sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   str:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

local path = ...
local output_root = split(path, ".")[1]
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

local function save_svg(polylines, attr)
  local id = attr.id
  local svg = {svg={g={polylines, _attr=attr}}}
  local t = xml2lua.toXml(svg, "", 0)
  local f = io.open(output_root.."/"..tostring(id)..".svg", "w")
  f:write(t)
  f:close()
end

local function split_g(g, desc)
  local chunks = {}
  local src_polyline = g.polyline
  for k, v in ipairs(src_polyline) do
    local tag = v._attr.tag
    if not chunks[tag] then
      chunks[tag] = {tag=tag}
      table.insert(chunks, chunks[tag])
    end
    table.insert(chunks[tag], k)
  end
  if #chunks == 1 then return end

  local bg = {}
  local new_ids = {}
  local parent_id = g._attr.id
  for k, v in ipairs(chunks) do
    local s = split(v.tag, ".")
    if #s == 1 then
      print("......................:", k, v.tag)
      for _, idx in ipairs(v) do
        table.insert(bg, src_polyline[idx])
      end
      table.insert(new_ids, parent_id)
    elseif #s == 3 then
      local attr = {id=string.format("%s.%d", parent_id, k), tag=s[2]}
      table.insert(new_ids, attr.id)
      local new_polylines = {}
      local new_g = {}
      new_g._attr = attr
      new_g.polyline = new_polylines
      for _, idx in ipairs(v) do
        table.insert(new_polylines, src_polyline[idx])
      end

      local minx, maxx, miny, maxy = bounds(new_g)
      desc[attr.id] = {bounds={minx, miny, maxx, maxy}, tag=attr.tag}

      save_svg(new_g, attr)
    else
      error("tag invalid:"..v.tag)
    end
  end
  assert(#bg>0, "chunk without bg "..g._attr.tag)
  g.polyline = bg
  return new_ids
end

local function split_svg(parser)
  local root = parser.handler.root
  local g = parser.handler.root.svg.g

  local desc = {}
  print("g count:", #g)
  for k, v in ipairs(g) do
      local new_ids = split_g(v, desc)

      local id = v._attr.id
      local minx, maxx, miny, maxy = bounds(v)
      desc[tostring(id)] = {bounds={minx, miny, maxx, maxy}, tag=v._attr.tag, children=new_ids}

      save_svg(v, v._attr)
  end

  local f = io.open(output_root.."/desc.json", "w")
  f:write(json:encode_pretty(desc))
  f:close()
end

local parser = read_xml(path)
split_svg(parser)
