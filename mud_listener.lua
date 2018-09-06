log = require "log"
local mudcontroller = require('mud_controller')
local json = require "cjson"

libunix = require "socket.unix"
skt_path = 'mud_controller_skt'
--clear old skt
os.remove(skt_path)

usocket = assert(libunix())
assert(usocket:bind(skt_path))
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

local function load_mud(data)
  status, request_obj = pcall(decode_json, data)
  if not status or request_obj == nil or type(request_obj) ~= 'table'  then
    return wrap_err_obj('err while encoding request json: ' .. request_obj)
  end

  if request_obj ~= nil then 
    local action = request_obj['action']
    local f_path = request_obj['file_path']
    local mac_addr = request_obj['mac_addr']

    if action == 'add' and mac_addr ~= nil and f_path  ~=  nil then
      log.info('Calling controller: ', f_path, ' > ', mac_addr )
      local response = mudcontroller.load(tostring(f_path), tostring(mac_addr))

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
    else
      return wrap_err_obj('Invalid call. Action not yet implemented. ' ..  data)
    end

  else
    log.error('Nil request obj')
  end

end

function listen()
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
       conn:send('{"action":"add", "mac_addr":"08:00:27:f0:5b:76", "file_path":"/root/iot_controller/toaster_mud.json"} \n')
    else
       local resp_data = load_mud(data) 
       log.info('Response obj: ', json.encode(resp_data))
       conn:send(json.encode(resp_data) .. "\n")
    end
    log.info('Waiting msg..')
    data, err = conn:receive()
  end
 
  log.warn('Connec evt: ', err)
  listen()
end

listen()
