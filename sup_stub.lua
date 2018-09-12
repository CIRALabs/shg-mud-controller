-- code that stubs the mud_supervisor 
-- for testing purposes only
-- to connect with the domain socket
-- First: lua mud_listener.lua
--   then lua sup_stub.lua

socket = require("socket")
socket.unix = require("socket.unix")
mudconfig = require("mud_config")

skt = assert(socket.unix())
local skt_path = mudconfig.sktpath
assert(skt:connect(skt_path))
print('skt connected: ', skt_path)

while 1 do
   print('Type data to send_')
   local msg = io.read()
   assert(skt:send(msg .. '\n' ))
   print('Waiting reply... \n')
   data, err = skt:receive()
   print("got back: \n", data .. "\n")
end

