local mudutil = { _version = "0.1.0" }

local protolabel = {
  [1] = 'icmp',
  [6] = 'tcp',
  [17] = 'udp',
  [41] = 'ipv6',
  [58] = 'ipv6-icmp',
  [89] = 'ospf'
}

function executeuci (ace)
  os.execute('uci del firewall.' .. ace.name  ..  ' > /dev/null 2>&1')
  os.execute('uci set firewall.' .. ace.name  ..  '=rule')

  os.execute('uci set firewall.' .. ace.name  ..  '.name=\''  .. ace.name  ..   '\'')
  os.execute('uci set firewall.' .. ace.name  ..  '.target=\'' .. ace.target ..  '\'')
  os.execute('uci set firewall.' .. ace.name  ..  '.proto=\'' .. ace.proto  ..   '\'')

  os.execute('uci set firewall.' .. ace.name  ..  '.src=\'iots\'')
  os.execute('uci set firewall.' .. ace.name  ..  '.src_mac=\''  .. ace.src_mac ..  '\'')
  if ace.src_port ~= nil then
    os.execute('uci set firewall.' .. ace.name  ..  '.src_port=\''  .. ace.src_port ..  '\'')
  end

  os.execute('uci set firewall.' .. ace.name  ..  '.dest=\'wan\'')
  os.execute('uci set firewall.' .. ace.name  ..  '.dest_ip=\'' ..ace.dest_ip ..  '\'')
  if ace.dest_port ~= nil then
    os.execute('uci set firewall.' .. ace.name  ..  '.dest_port=\''  .. ace.dest_port ..  '\'')
  end

  os.execute('uci set firewall.' .. ace.name  ..  '.enabled=1')
  os.execute('uci reorder firewall.' .. ace.name  ..  '=0')

  os.execute('uci commit firewall')
  os.execute('/etc/init.d/firewall restart > /dev/null 2>&1')

  log.info(' UCI fw rule created: ', ace.name, ' - ', ace.src_mac, ' > ', ace.dest_ip  )
end

--TODO
resolvename = function(name)
  return '8.8.8.8'
end

function geturlproto(type, ace)
  if type == 'ipv6-acl-type' then
    return ace.matches.ipv6['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv6.protocol
  else
    return ace.matches.ipv4['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv4.protocol
  end
end

mudutil.createrule = function (acl)
  --log.info('Reading ACL spec: ', acl.name)
  if( acl.aces.ace) ~= nil then
    for k, v in pairs(acl.aces.ace) do

      url, proton = geturlproto(acl.type, v)
      ace_info = {
        --TODO we shouldnt rely on v.name it can be invalid for uci
        name = v.name, target = v.matches.actions.forwarding, proto=proton,
        src='iots', src_mac=mac_addr,
        dest='wan', dest_ip=resolvename(url)
      }

      protoobj = v.matches[protolabel[proton]]
      log.info(k, ' ACE: ', v.name,  ' proto : ', protolabel[proton]  )
      log.info(' url: ', url)
      if protoobj ~= nil then
        if protoobj['source-port'] then
          log.info(' src  port : ', protoobj['source-port']['port'])
          ace_info.src_port = protoobj['source-port']['port']
        else
          log.info(' src port : no_port')
        end

        if protoobj['destination-port'] then
          log.info(' dest port : ', protoobj['destination-port']['port'])
          ace_info.dest_port = protoobj['destination-port']['port']
        else
          log.info(' dest port : no_port')
        end

      end

      executeuci(ace_info)

    end
  else
    log.warn('no ace found in acl: ', acl.name)
  end
end

return mudutil
