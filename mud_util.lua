local mudutil = { _version = "0.1.0" }
local uci = require('uci')
local fw = 'firewall'
local muddigger = require('mud_digger')
ucic = uci.cursor()

local protolabel = {
  [1] = 'icmp',
  [6] = 'tcp',
  [17] = 'udp',
  [41] = 'ipv6',
  [58] = 'ipv6-icmp',
  [89] = 'ospf'
}

function executeuci(rule)
  ucic.delete(fw, rule.name)
  ucic.commit(fw)

  ucic.set(fw, rule.name, 'rule')
  for k, v in pairs(rule) do
    ucic.set(fw, rule.name, k, v)
  end

  ucic.reorder(fw, rule.name, 0)
  ucic.commit(fw)

  os.execute('/etc/init.d/firewall restart > /dev/null 2>&1')
  log.info(' >>> UCI fw rule created: ', rule.name, ' - ', rule.src_mac, ' > ', rule.dest_ip  )

end

function geturlproto(type, ace)
  if type == 'ipv6-acl-type' then
    return ace.matches.ipv6['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv6.protocol, 'ipv6'
  else
    return ace.matches.ipv4['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv4.protocol, 'ipv4'
  end
end

mudutil.createrule = function (acl)
  if( acl.aces.ace) ~= nil then
    for k, v in pairs(acl.aces.ace) do

      url, proton, ipv = geturlproto(acl.type, v)
      local digtype = (ipv == 'ipv4' and 'A' or 'AAAA')

      ace_info = {
        --TODO we shouldnt rely on v.name it can be invalid for uci
        name = v.name, target = v.matches.actions.forwarding, proto=proton,
        src='iots', src_mac=mac_addr,
        dest='wan'
      }

      protoobj = v.matches[protolabel[proton]]
      log.info(k, ' ACE: ', v.name,  ' proto : ', protolabel[proton]  )
      log.info(' url: ', url, ' (', digtype, ')' )
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

      --creates one iptables rule per resolved ip type
      recs = muddigger.dig(url, digtype)

      if next(recs) then
        local basename = ace_info.name
        for i, v in ipairs(recs) do
          ace_info.dest_ip = v
          ace_info.name = basename .. '_' .. ipv .. '_' .. i
          executeuci(ace_info)
        end
      else
        log.warn('Skipping rule for: ', url, ' no ips retrieved.')
      end


    end
  else
    log.warn('no ace found in acl: ', acl.name)
  end
end

return mudutil
