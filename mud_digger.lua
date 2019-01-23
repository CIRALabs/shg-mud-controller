local mudconfig = require("mud_config")

local muddigger = { _version = "0.1.0" }

local json = require("cjson")

local Resolver = require("dns.resolver")
local rInst = Resolver.new(mudconfig.resolvers, mudconfig.timeout)

if mudconfig.disable_dns_cache then
  rInst:disableCache()
end

-- Map rulename -> qname -> type -> values
local monitoredNames = {}

function resolve(qname, type)
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

muddigger.dig = function (rulename, qname, type)
    resp = resolve(qname, type)
    table.sort(resp)
  -- Save list of response to monitored list
  if monitoredNames[rulename] == nil then
    monitoredNames[rulename] = {[qname] = {[type] = resp}}
  elseif monitoredNames[rulename][qname] == nil then
    monitoredNames[rulename][qname] = {[type] = resp}
  else
    monitoredNames[rulename][qname][type] = resp
  end

    log.debug('Monitored names: ')
    log.debug(json.encode(monitoredNames))

    return resp
end

muddigger.remove = function (rulename)
    monitoredNames[rulename] = nil
end

muddigger.monitor = function(cb)
  log.info("Starting monitoring...")
  for rulename, by_qname in pairs(monitoredNames) do
    for qname, by_type in pairs(by_qname) do
      for type, cached_resp in pairs(by_type) do
        resp = resolve(qname, type)
        table.sort(resp)
        log.debug("Cached data for", rulename, ' - ', qname, ' - ', type, ': ', json.encode(cached_resp))
        log.debug("Newly resolved data: ", json.encode(resp))
        if not deepcompare(resp, cached_resp) then
          -- Update monitor
          by_type[type] = resp
          -- Refresh rule
          log.debug("Refresh rule ", rulename)
          cb(rulename, type, resp)
        end
      end
    end
  end
end

-- From https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3,
-- MIT license
-- Lists must have the same element order to be equal
function deepcompare(t1,t2,ignore_mt)
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
        if v2 == nil or not deepcompare(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepcompare(v1,v2) then return false end
    end
    return true
end


return muddigger

