log = require "log"
local mudcontroller = require('mud_controller')
local json = require "cjson"

libunix = require "socket.unix"
skt_path = 'mud_controller_skt'
os.remove(skt_path)

usocket = assert(libunix())
assert(usocket:bind(skt_path))
assert(usocket:listen())

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function load_mud(data)
  request_obj = json.decode(data)
  if request_obj ~= nil then 
    local action = request_obj['action']
    local f_path = request_obj['file_path']
    local mac_addr = request_obj['mac_addr']

    if action == 'add' and mac_addr ~= nil and f_path  ~=  nil then
      log.info('Calling controller: ', f_path, ' > ', mac_addr )
      local response = mudcontroller.load(tostring(f_path), tostring(mac_addr))

      --loop through rules so that cjson does not insert keys in the response
      local new_rules = {}
      local i = 1
      for k,v in pairs (response.rules) do 
        new_rules[i]  = v
        i = i + 1
      end
      response.rules = new_rules      
      return response
    else
      print('Invalid call: ', data)
    end

  else
    log.error('Nil request obj')
  end

end

function listen()
  log.info('Listening on: ', skt_path)

  conn = assert(usocket:accept())
  log.info(' --- Connected! --- ')
  data, err = conn:receive()
 
  while not err do
    log.info("got msg> " .. data)
    if data == 'hi' then
       print('\n\n HELLO! \n\n ')
       conn:send("hey \n" )
    elseif data == 'hello' then
       print('\n\n HI! \n\n')
       conn:send("hey \n" )
    elseif data == 'checkrules' or data == 'check rules' then
       print('#iptables -L -n -v | grep iot_to')
       os.execute('iptables -L -n -v | grep iot_to')

       print('#ip6tables -L -n -v | grep iot_to')
       os.execute('ip6tables -L -n -v | grep iot_to')
    elseif data == 'helpp' then 
       checkdata('load /root/iot_controller/toaster_mud.json into 11:22:33:44:55:66')
    else
       local resp_data = load_mud(data) 
       log.info('Response obj: ', json.encode(resp_data))
       conn:send(json.encode(resp_data) .. "\n")
    end
    log.info('Waiting skt msg..')
    data, err = conn:receive()
  end
 
  log.warn('Connec evt: ', err)
  listen()
end

listen()
