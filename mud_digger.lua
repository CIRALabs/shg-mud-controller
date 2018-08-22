mud_dlocal muddigger = { _version = "0.1.0" }
local Resolver = require( "dns.resolver")
local r = Resolver.new({"8.8.8.8"}, 2)

muddigger.dig = function (qname, type)
  resp = {}
  --using raw to grab answers only - dont care about additional
  local recs, errmsg = r:resolveRaw(qname, type)
  if recs and recs.answers then
    local c = 1
    for k, v in pairs(recs.answers) do
      if v.type == type then
        resp[c] = v.content
        c = c + 1
      end
    end
  end
  return resp
end

