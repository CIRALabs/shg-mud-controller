
# MUD controller Proof of Concept
 * Engine to be executed in the SecureHomeGateway. 
 * After a new device has entered the network and it's confirmation is sent through the mobile app this MUD controller is then triggered in order to: Read the MUD file and create the appropriate firewall rules in the SHG.
 
## Features: 
   * Parse local MUD json file 
   * Identify ACLs/ACEs
   * Resolve urls 
   * Create new firewall rules using uci
   * Create one iptables rule per retrieved IP
   
### Deps
 * http://downloads.openwrt.org/releases/18.06.0/packages/i386_pentium4/base/libuci-lua_2018-08-11-4c8b4d6e-1_i386_pentium4.ipk
 * https://github.com/mpx/lua-cjson 
 * http://downloads.openwrt.org/releases/18.06.0/packages/i386_pentium4/packages/luasocket_3.0-rc1-20130909-4_i386_pentium4.ipk
 * https://github.com/zeitgeist87/LuaResolver 
 * https://github.com/rxi/log.lua 
 
   
## Usage   

##### Check config opts in mud_config.lua
###### Both zones should already exist in the routes before onboarding devices
```angular2html
  mudconfig.iotszone = "iots"
  mudconfig.wanzone = "wan"
```

###### Socket path can also be tweked at
```angular2html
  mudconfig.sktpath = "mud_controller_skt"
``` 

##### Start init controller
```bash
   lua init.lua
```
 
 * This will create a socket on the execution folder.
 ```angular2html
srwxr-xr-x    1 root     root             0 Sep 12 15:03 mud_controller_skt=
```
 
##### Start stub to send msgs
```bash
   lua sup_stub.lua
```

 * To load a new MUD file send a json msg in the following format:
```bash
  {"action":"add", "mac_addr":"<mac>", "file_path":"<file_path>"}
```

 * Reponse will be in the following format:
```bash
  {"status":"ok", "mac_addr":"<mac>", "rules":["rule_xpto", "rule_qwert"]}
```



 * To delete rules:
```bash
  {"action":"del", "rules":["rule_xpto", "rule_qwert"]}
```

 * Successful reponse will be in the following format:
```bash
  {"status":"ok","rules":["rule_xpto":"ok","rule_qwert":"ok"]}
```

 * If a given Rule is Not Found (rnf) response will include an error per rule.
```bash
   {"status":"err","rules":{"rule_xpto":"rnf","rule_qwert":"rnf"}
```


