


# MUD controller Proof of Concept
 * Engine that will be executed in the SHG. After a new device has entered the network and it's confirmation is sent through the mobile app this MUD controller is then triggered in order to: Read the MUD file and create the appropriate firewall rules in the SHG.
 
 
## What we have: 
   * Parse local MUD json file 
   * Identify acls/aces
   * Creates new firewall rule using uci - bindings for lua
   * Resolve urls 
   * Creates one iptables rule per retrieved IP
   
## We don't yet

   * manage rule name - instead of just using it from mud file 

### deps
 * https://github.com/rxi/log.lua
 * https://github.com/mpx/lua-cjson 
 * http://downloads.openwrt.org/releases/18.06.0/packages/x86_64/base/libuci-lua_2018-08-11-4c8b4d6e-1_x86_64.ipk
 * https://github.com/zeitgeist87/LuaResolver
   
Usage   
```bash
   lua mud_controller <mud_file_path> <mac_addr>
```
   
eg.:
```bash
root@OpenWrt:~/iot_controller# lua mud_controller.lua toaster_mud.json '08:00:27:f0:5b:76'
[INFO  19:25:59] mud_controller.lua:2: CiraLabs MUD interpreter... o/
[INFO  19:25:59] mud_controller.lua:22: >>>  toaster_mud.json  loaded successfully!
[INFO  19:25:59] mud_controller.lua:28: Parsing MUD for  https://cira.ca/mud/smarttoaster2k
[INFO  19:25:59] mud_controller.lua:29: sysinfo:  SmartToaster 2K
[INFO  19:25:59] mud_controller.lua:30: device supported?:  true
[INFO  19:25:59] mud_controller.lua:31: last-pdate:  2018-08-02T17:12:07+02:00
[INFO  19:25:59] mud_controller.lua:39: Declared ACL (from):  1 mud-41611-v4fr
[INFO  19:25:59] mud_controller.lua:39: Declared ACL (from):  2 mud-41612-v4fr
[INFO  19:25:59] mud_controller.lua:39: Declared ACL (from):  3 mud-41613-v4fr
[WARN  19:25:59] mud_controller.lua:53: No 'to-device-policy' declared.
[INFO  19:25:59] mud_controller.lua:59: ACL spec (from):  mud-41611-v4fr
[INFO  19:25:59] ./mud_util.lua:68: 1  ACE:  iot_toaster_ping  proto :  icmp
[INFO  19:25:59] ./mud_util.lua:69:  url:  cira.ca
[INFO  19:25:59] ./mud_util.lua:38:  UCI fw rule created:  iot_toaster_ping  -  08:00:27:f0:5b:76  >  8.8.8.8
[INFO  19:25:59] mud_controller.lua:59: ACL spec (from):  mud-41612-v4fr
[INFO  19:25:59] ./mud_util.lua:68: 1  ACE:  iot_toaster_app  proto :  tcp
[INFO  19:25:59] ./mud_util.lua:69:  url:  cira.ca
[INFO  19:25:59] ./mud_util.lua:38:  UCI fw rule created:  iot_toaster_app  -  08:00:27:f0:5b:76  >  8.8.8.8
[INFO  19:25:59] ./mud_util.lua:68: 2  ACE:  iot_toaster_dns  proto :  tcp
[INFO  19:25:59] ./mud_util.lua:69:  url:  ns1.ciralabs.ca
[INFO  19:25:59] ./mud_util.lua:75:  src port : no_port
[INFO  19:25:59] ./mud_util.lua:79:  dest port :  53
[INFO  19:25:59] ./mud_util.lua:38:  UCI fw rule created:  iot_toaster_dns  -  08:00:27:f0:5b:76  >  8.8.8.8
[INFO  19:25:59] ./mud_util.lua:68: 3  ACE:  iot_toaster_update  proto :  udp
[INFO  19:25:59] ./mud_util.lua:69:  url:  update.ciralabs.ca
[INFO  19:25:59] ./mud_util.lua:72:  src  port :  7500
[INFO  19:25:59] ./mud_util.lua:79:  dest port :  9000
[INFO  19:25:59] ./mud_util.lua:38:  UCI fw rule created:  iot_toaster_update  -  08:00:27:f0:5b:76  >  8.8.8.8
[INFO  19:25:59] mud_controller.lua:59: ACL spec (from):  mud-41613-v4fr
[INFO  19:25:59] ./mud_util.lua:68: 1  ACE:  iot_toaster_google  proto :  tcp
[INFO  19:25:59] ./mud_util.lua:69:  url:  www.google-analytics.com
[INFO  19:25:59] ./mud_util.lua:75:  src port : no_port
[INFO  19:25:59] ./mud_util.lua:79:  dest port :  443
[INFO  19:25:59] ./mud_util.lua:38:  UCI fw rule created:  iot_toaster_google  -  08:00:27:f0:5b:76  >  8.8.8.8

```
