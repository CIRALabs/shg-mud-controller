log = require("log")
mudconfig = require("mud_config")

local mudcontroller = require("mud_controller")
local json = require("cjson")
local libunix = require("socket.unix")
local luaevent = require("luaevent")

local mudlistener = { _version = "0.1.1" }

skt_path = mudconfig.sktpath

--clear old skt
os.remove(skt_path)

local usocket = assert(libunix())
assert(usocket:bind(skt_path))
usocket:settimeout(0)

--tweak socket perms: mud group
os.execute('chmod g+w ' .. skt_path)
os.execute('chgrp mud ' .. skt_path)

assert(usocket:listen())

--json decode wrapper for pcall
function decode_json(data)
  return json.decode(data)
end

function wrap_err_obj(msg)
  local err_resp = {}
  err_resp.status = 'err'
  err_resp.msg = msg
  return err_resp
end

local function add(data)
  status, request_obj = pcall(decode_json, data)
  if not status or request_obj == nil or type(request_obj) ~= 'table'  then
    return wrap_err_obj('err while encoding request json: ' .. request_obj)
  end

  if request_obj ~= nil then
    local action = request_obj['action']
    local f_path = request_obj['file_path']
    local mac_addr = request_obj['mac_addr']
    local rules = request_obj['rules']

    if action == 'add' and mac_addr ~= nil and f_path  ~=  nil then
      log.info('Calling controller: ', f_path, ' > ', mac_addr )
      local response = mudcontroller.add(tostring(f_path), tostring(mac_addr))

      --loop through rules so that cjson does not insert keys in the response
      if response ~= nill and response.status == 'ok' and response.rules ~= nil then
        local new_rules = {}
        for basename, rules in pairs (response.rules) do
          new_rules[basename] = rules
        end
        response.rules = new_rules
      end

      return response
    elseif action == 'del' and rules ~= nil then
      local response = mudcontroller.del(rules)
      return response
    elseif action == 'monitor' then
      mudcontroller.monitor()
    else
      return wrap_err_obj('Invalid call. Action not yet implemented. ' ..  data)
    end

  else
    log.error('Nil request obj')
  end

end

mudlistener.listen = function ()
  log.info('Listening on: ', skt_path)
  luaevent.addserver(usocket, process)
  -- Need to keep reference to event otherwise it is garbage collected
  local monitor_ev = luaevent.addevent(nil, luaevent.core.EV_TIMEOUT, function(ev)
    log.debug("Start periodic monitoring")
    mudcontroller.monitor()
    log.debug("End periodic monitoring")
  end, mudconfig.monitoring_period)
  luaevent.loop()
end


function process(skt)
  while true do
    local data, ret = luaevent.receive(skt)
    log.info("got msg> " .. data)
    if ret == 'closed' then
      break
    elseif data == 'hi'or data == 'hello' then
      print('\n\n HELLO! \n\n ')
      luaevent.send(skt, "hey \n" )
    elseif data == 'checkrules' or data == 'check rules' then
      print('#iptables -L -n -v | grep iot_to')
      os.execute('iptables -L -n -v | grep iot_to')
      print('#ip6tables -L -n -v | grep iot_to')
      os.execute('ip6tables -L -n -v | grep iot_to')
      luaevent.send(skt, 'ok\n')
    elseif data == 'help' then
      luaevent.send(skt, '{"action":"add", "mac_addr":"08:00:27:f0:5b:76", "file_path":"/root/repos/shg-mud-controller/toaster_mud.json"} \n')
    elseif data == 'helpdel' then
      luaevent.send(skt, '{"action":"del", "rules":["iot_toaster_to","iot_toaster_app","iot_toaster_google","iot_toaster_dns","iot_toaster_ping","iot_toaster_update"]}  \n')
    elseif data == 'monitor' then
      mudcontroller.monitor()
      luaevent.send(skt, 'ok\n')
    else
      local resp_data = add(data)
      log.info('Response obj: ', json.encode(resp_data))
      luaevent.send(skt, json.encode(resp_data) .. "\n")
    end
  end
  skt:close()
end

return mudlistener
