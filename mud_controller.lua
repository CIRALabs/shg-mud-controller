LUA_PATH = '/usr/lib/lua/mud-super/?.lua'

log = require "log"
log.outfile = '/var/log/mud_controller.log'
local json = require "cjson"
local util = require "cjson.util"
local mudutil = require "mud_util"

local mudcontroller = { _version = "0.1.0" }

mudcontroller.del = function(todel)
  local obj_resp = mudutil.delrules(todel)
  return obj_resp
end

function decode_f(f_path)
   l_file = assert(util.file_load(f_path))
   return json.decode(l_file)
end

mudcontroller.add = function(f_path, mac_addr)
  log.info('Loading file: ', f_path, ' for ', mac_addr )

  status, mud_obj = pcall(decode_f, f_path)
  if not status then
    return wrap_err_obj('Error loading mud file: ' ..  mud_obj)
  end

  log.info('Parsing MUD for ', mud_obj['ietf-mud:mud']['mud-url'])
  log.info('sysinfo: ', mud_obj['ietf-mud:mud']['systeminfo'])
  log.info('device supported?: ', mud_obj['ietf-mud:mud']['is-supported'])
  log.info('last-pdate: ', mud_obj['ietf-mud:mud']['last-update'])

  f_dev_pols = {}
  t_dev_pols = {}
  
  --retrieving FROM dev policies
  if mud_obj['ietf-mud:mud']['from-device-policy'] ~= nil then
     for k, v in pairs(mud_obj['ietf-mud:mud']['from-device-policy']['access-lists']['access-list']) do
        log.info('Declared ACL (from): ', k, v.name)
        f_dev_pols[v.name] = {}
     end
  else
     log.warn('No \'from-device-policy\' declared.')
  end

  --retrieving TO dev policies
  if mud_obj['ietf-mud:mud']['to-device-policy'] ~= nil then
     for k, v in pairs(mud_obj['ietf-mud:mud']['to-device-policy']['access-lists']['access-list']) do
        log.info('Declared ACL (to): ', k, v.name)
        t_dev_pols[v.name] = {}
     end
  else
     log.warn('No \'to-device-policy\' declared.')
  end

  local all_rules = {}
  for k,v in pairs(mud_obj['ietf-access-control-list:acls']['acl']) do
     if f_dev_pols[v.name] ~= nil then
        f_dev_pols[v.name] = v
        log.info('ACL spec (from): ', v.name)
        local rule_response = mudutil.createrule(v, mac_addr, 'fr')
        for k,v in pairs(rule_response) do all_rules[k] = v end
     elseif t_dev_pols[v.name] ~= nil then
        t_dev_pols[v.name] = v
        log.info('ACL spec (to): ', v.name)
        local rule_response = mudutil.createrule(v, mac_addr, 'to')
        for k,v in pairs(rule_response) do all_rules[k] = v end
     else
       log.warn('ACL declared but not assigned to device: ', v.name)
     end
  end

  --creates table obj to send back
  local obj_resp = {}
  obj_resp["status"] = "ok"
  obj_resp["mac_addr"] = mac_addr
  obj_resp["rules"] = all_rules
  return obj_resp    
end

return mudcontroller
