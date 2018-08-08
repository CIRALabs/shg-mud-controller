
local log = require "log"
log.info('CiraLabs MUD interpreter... o/')
log.outfile = 'ciralabs.log'
local json = require "cjson"
local util = require "cjson.util"
local mudutil = require "mud_util"

f_path = arg[1]
mac_addr = arg[2]
if f_path == nil or mac_addr == nil then
   log.error('no file_path or mac_addr! will halt! ')
   log.info('Usage: lua mud_controller <mud_file_path> <mac_addr>')
   return
end

function decode_f()
   mud_obj = json.decode(util.file_load(f_path))
end

f_status, f_err = pcall(decode_f)
if (f_status) then
   log.info('>>> ', f_path, " loaded successfully!")
else
   log.error('Error loading file: ', f_err)
   return
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
      log.info('fr->> ', k, v.name)
      f_dev_pols[v.name] = {}
   end
else
   log.warn('No \'from-device-policy\' declared.')
end

--retrieving TO dev policies
if mud_obj['ietf-mud:mud']['to-device-policy'] ~= nil then
   for k, v in pairs(mud_obj['ietf-mud:mud']['to-device-policy']['access-lists']['access-list']) do
      log.info('to->> ', k, v.name)
      t_dev_pols[v.name] = {}
   end
else
   log.warn('No \'to-device-policy\' declared.')
end


function geturlproto(type, ace)
   if type == 'ipv6-acl-type' then
      return ace.matches.ipv6['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv6.protocol
   else
      return ace.matches.ipv4['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv4.protocol
   end
end


function create_rule(acl)
   log.info('creating rule for ', acl.name)
   if( acl.aces.ace) ~= nil then
      for k, v in pairs(acl.aces.ace) do
         url, proto = geturlproto(acl.type, v)
         ace_info = {
            --TODO we shouldnt rely on v.name it can be invalid for uci
            name = v.name, target = v.matches.actions.forwarding, proto=proto,
            src='iots', src_mac=mac_addr,
            dest='wan', dest_ip=mudutil.resolvename(url)
         }
         mudutil.executeuci(ace_info)
      end
   else
      log.warn('no ace found in acl: ', acl.name)
   end

end


for k,v in pairs(mud_obj['ietf-access-control-list:acls']['acl']) do
   if f_dev_pols[v.name] ~= nil then
      f_dev_pols[v.name] = v
      log.info('Added to f_dev_pols:: ', v.name)
      create_rule(v)
   elseif t_dev_pols[v.name] ~= nil then
      t_dev_pols[v.name] = v
      log.info('Added to t_dev_pols:: ', v.name)
      create_rule(v)
   else
     log.warn('ACL declared but not assigned to device: ', v.name)
   end
end
