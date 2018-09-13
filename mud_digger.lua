local mudconfig = require("mud_config")
local muddigger = { _version = "0.1.0" }

local Resolver = require("dns.resolver")
local rInst = Resolver.new(mudconfig.resolvers, mudconfig.timeout)

muddigger.dig = function (qname, type)
  resp = {}
  --using resolveRaw to grab answers only - discard additional
  local recs, errmsg = rInst:resolveRaw(qname, type)
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

return muddigger

