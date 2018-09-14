local module_folder = "/usr/lib/lua/mud-controller/"
package.path = module_folder .. "?.lua;" .. package.path

require("mud_listener").listen()


