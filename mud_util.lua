local mudutil = { _version = "0.1.0" }
local json = require("cjson")
local util = require("cjson.util")

mudutil.starts_with = function (str, start)
  if str == nil then return false end
  return str:sub(1, #start) == start
end

mudutil.rule_match_name = function(name, rule)
  return (mudutil.starts_with(rule['.name'], name) or mudutil.starts_with(rule['name'], name)) and rule['.type'] == 'rule'
end

mudutil.decode_f = function(f_path)
  local l_file = assert(util.file_load(f_path))
  return json.decode(l_file)
end

mudutil.save_f = function(f_path, data)
  local j_data = json.encode(data)
  util.file_save(f_path, j_data)
end


-- From https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3,
-- MIT license
-- Lists must have the same element order to be equal
mudutil.deepcompare = function(t1,t2,ignore_mt)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  if not ignore_mt and mt and mt.__eq then return t1 == t2 end
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not mudutil.deepcompare(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not mudutil.deepcompare(v1,v2) then return false end
  end
  return true
end

return mudutil