

local mudconfig  = { _version = "0.1.0" }

--src zone when it's a FROM device police - dest zone when it's TO device
mudconfig.iotszone = "iots"

--dest zone when it's a FROM device police - src zone when it's TO device
mudconfig.wanzone = "wan"

--unix socket path to listen to 
mudconfig.sktpath = "mud_controller_skt"

return mudconfig

