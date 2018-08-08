


# MUD controller Proof of Concept
## What we have: 
   * Parse local MUD json file 
   * Identify acls/aces
   * Creates new firewall rule using uci
   
## We DONT yet
   * Resolve url into IP 
   * manage rule name - instead of just using mud name 
   * download mud file
   * deal with ports
   * deal with from/to device 
   * deal with operators in matching rules
   * mud validation

###deps
 * https://github.com/rxi/log.lua
 * https://github.com/mpx/lua-cjson   
   
Usage   
```bash
   lua mud_controller <mud_file_path> <mac_addr>
```
   
eg.:
```bash
root@OpenWrt:~/iot_controller# lua mud_controller.lua toaster_mud.json '08:00:27:13:89:9E'
[INFO  18:38:28] mud_controller.lua:2: CiraLabs MUD interpreter... o/
[INFO  18:38:28] mud_controller.lua:22: >>>  toaster_mud.json  loaded successfully!
[INFO  18:38:28] mud_controller.lua:29: Parsing MUD for  https://cira.ca/mud/ciratoaster
[INFO  18:38:28] mud_controller.lua:30: sysinfo:  Lets toast! o
[INFO  18:38:28] mud_controller.lua:31: device supported?:  true
[INFO  18:38:28] mud_controller.lua:32: last-pdate:  2018-08-02T17:12:07+02:00
[INFO  18:38:28] mud_controller.lua:40: fr->>  1 mud-41611-v4fr
[WARN  18:38:28] mud_controller.lua:54: No 'to-device-policy' declared.
[INFO  18:38:28] mud_controller.lua:90: Added to f_dev_pols::  mud-41611-v4fr
[INFO  18:38:28] mud_controller.lua:68: creating rule for  mud-41611-v4fr
```