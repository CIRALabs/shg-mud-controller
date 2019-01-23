log = require("log")
mudconfig = require("mud_config")

local mudcontroller = require("mud_controller")
local json = require("cjson")
local libunix = require("socket.unix")

local mudlistener = { _version = "0.1.1" }

skt_path = mudconfig.sktpath

--clear old skt
os.remove(skt_path)

usocket = assert(libunix())
assert(usocket:bind(skt_path))

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
        local i = 1
        for k,v in pairs (response.rules) do
          new_rules[i]  = v
          i = i + 1
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

  conn = assert(usocket:accept())
  log.info(' --- Connected! --- ')
  log.info('Waiting msg..')
  data, err = conn:receive()

  while not err do
    log.info("got msg> " .. data)
    if data == 'hi'or data == 'hello' then
       print('\n\n HELLO! \n\n ')
       conn:send("hey \n" )
    elseif data == 'checkrules' or data == 'check rules' then
       print('#iptables -L -n -v | grep iot_to')
       os.execute('iptables -L -n -v | grep iot_to')
       print('#ip6tables -L -n -v | grep iot_to')
       os.execute('ip6tables -L -n -v | grep iot_to')
       conn:send('ok\n')
    elseif data == 'help' then
       conn:send('{"action":"add", "mac_addr":"08:00:27:f0:5b:76", "file_path":"/root/repos/shg-mud-controller/toaster_mud.json"} \n')
    elseif data == 'helpdel' then
       conn:send('{"action":"del", "rules":["iot_toaster_ping_cnn_ipv4_1","iot_toaster_tr_cira_ipv4_1","iot_toaster_ping_cnn_ipv4_3","iot_toaster_google_ipv6_1","iot_toaster_google_ipv4_1","iot_toaster_dns_ipv4_1","iot_toaster_ping_cira_ipv4_1","iot_toaster_ping_cnn_ipv4_4","iot_toaster_app_ipv6_1","iot_toaster_app_ipv4_1","iot_toaster_ping_cnn_ipv4_2", "iot_toaster_ping_ipv4_1", "iot_toaster_to_ipv4_1"]}  \n')
    elseif data == 'monitor' then
        mudcontroller.monitor()
        conn:send('ok\n')
    else
       local resp_data = add(data)
       log.info('Response obj: ', json.encode(resp_data))
       conn:send(json.encode(resp_data) .. "\n")
    end
    log.info('Waiting msg..')
    data, err = conn:receive()
  end

  log.warn('Connec evt: ', err)

  mudlistener.listen()
end

return mudlistener
