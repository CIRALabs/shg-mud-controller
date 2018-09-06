
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
 * https://github.com/rxi/log.lua 

#### Pre-committed:
 * https://github.com/zeitgeist87/LuaResolver 
 * https://github.com/mpx/lua-cjson 
   
##Usage   
####Start listener
```bash
   lua mud_listener.lua
```
 
 * This will create a mud_controller_skt on the execution folder.
 
 ####Start stub to send msgs
```bash
   lua sup_stub.lua
```

 * To load a new MUD file send a json msg in the following format:
```bash
{"action":"add", "mac_addr":"<mac>", "file_path":"<file_path>"}
```

* Reponse will be in the following format:
```bash
{"status":"ok", "mac_addr":"11:22:33:44:55:66", "rules":["rule_xpto", "rule_qwert"]}
```