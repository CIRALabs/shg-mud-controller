local muddigger = { _version = "0.1.0" }

local json = require("cjson")
local mudconfig = require("mud_config")
local mudutil = require("mud_util")

local Resolver = require("dns.resolver")
local rInst = Resolver.new(mudconfig.resolvers, mudconfig.timeout)

if mudconfig.disable_dns_cache then
  rInst:disableCache()
end

local function initmonitoring()
  local status, obj = pcall(mudutil.decode_f, mudconfig.statepath)
  if not status then
    obj = {}
  end
  return obj
end

-- Map rulename -> qname -> type -> values
local monitoredNames = initmonitoring()

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
  table.sort(resp)-- Save list of response to monitored list
  if monitoredNames[rulename] == nil then
    monitoredNames[rulename] = {[qname] = {[type] = resp}}
  elseif monitoredNames[rulename][qname] == nil then
    monitoredNames[rulename][qname] = {[type] = resp}
  else
    monitoredNames[rulename][qname][type] = resp
  end

  log.debug('Monitored names: ')
  log.debug(json.encode(monitoredNames))

  mudutil.save_f(mudconfig.statepath, monitoredNames)

  return resp
end

muddigger.remove = function (rulename)
  monitoredNames[rulename] = nil
  mudutil.save_f(mudconfig.statepath, monitoredNames)
end

muddigger.monitor = function(cb)
  log.info("Starting monitoring...")
  local update = false
  for rulename, by_qname in pairs(monitoredNames) do
    for qname, by_type in pairs(by_qname) do
      for type, cached_resp in pairs(by_type) do
        resp = resolve(qname, type)
        table.sort(resp)
        log.debug("Cached data for", rulename, ' - ', qname, ' - ', type, ': ', json.encode(cached_resp))
        log.debug("Newly resolved data: ", json.encode(resp))
        if not mudutil.deepcompare(resp, cached_resp) then
          -- Update monitor
          by_type[type] = resp
          -- Refresh rule
          log.debug("Refresh rule ", rulename)
          cb(rulename, type, resp)
          update = true
        end
      end
    end
  end
  if update then
    mudutil.save_f(mudconfig.statepath, monitoredNames)
  end
end

return muddigger

