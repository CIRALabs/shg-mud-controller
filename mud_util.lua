local mudutil = { _version = "0.1.0" }

mudutil.executeuci = function (ace)
   os.execute('uci del firewall.' .. ace.name  ..  ' > /dev/null 2>&1')
   os.execute('uci set firewall.' .. ace.name  ..  '=rule')

   os.execute('uci set firewall.' .. ace.name  ..  '.name=\''  .. ace.name  ..   '\'')
   os.execute('uci set firewall.' .. ace.name  ..  '.target=\'' .. ace.target ..  '\'')
   os.execute('uci set firewall.' .. ace.name  ..  '.proto=\'' .. ace.proto  ..   '\'')

   os.execute('uci set firewall.' .. ace.name  ..  '.src=\'iots\'')
   os.execute('uci set firewall.' .. ace.name  ..  '.src_mac=\''  .. ace.src_mac ..  '\'')

   os.execute('uci set firewall.' .. ace.name  ..  '.dest=\'wan\'')
   os.execute('uci set firewall.' .. ace.name  ..  '.dest_ip=\'' ..ace.dest_ip ..  '\'')

   os.execute('uci set firewall.' .. ace.name  ..  '.enabled=1')
   os.execute('uci reorder firewall.' .. ace.name  ..  '=0')

   os.execute('uci commit firewall')
   os.execute('/etc/init.d/firewall reload > /dev/null 2>&1')
end

--TODO
mudutil.resolvename = function(name)
   return '8.8.8.8'
end

return mudutil

