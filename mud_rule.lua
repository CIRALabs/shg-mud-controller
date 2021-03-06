local mudrule = { _version = "0.1.0" }
local fw = "firewall"
local uci = require("uci")
local muddigger = require("mud_digger")
local mudutil = require("mud_util")

local ucic = uci.cursor()

local protolabel = {
  [1] = 'icmp',
  [6] = 'tcp',
  [17] = 'udp',
  [41] = 'ipv6',
  [58] = 'ipv6-icmp',
  [89] = 'ospf'
}

local function restartFw()
  os.execute('/etc/init.d/firewall restart > /dev/null 2>&1')
end

local function executeuci(rule)
  ucic.delete(fw, rule.name)
  ucic.commit(fw)

  ucic.set(fw, rule.name, 'rule')
  for k, v in pairs(rule) do
    ucic.set(fw, rule.name, k, tostring(v))
  end

  ucic.reorder(fw, rule.name, 0)
  ucic.commit(fw)

  restartFw()
  str_msg = " >>> UCI fw rule created: "
  if rule.src_mac ~= nil then
    log.info(str_msg, rule.name, ' - ', rule.src_mac, ' > ', rule.dest_ip  )
  else
    log.info(str_msg, rule.name, ' - ', rule.src_ip, ' > ', rule.dest_mac  )
  end

end

local function geturlproto(type, ace)
  if type == 'ipv6-acl-type' then
    return ace.matches.ipv6['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv6.protocol, 'ipv6'
  else
    return ace.matches.ipv4['ietf-acldns:s:qrc-dnsname'], ace.matches.ipv4.protocol, 'ipv4'
  end
end

mudrule.delrules = function(todel)
  local resp_obj = {}
  resp_obj['status'] = "ok"
  resp_obj['rules'] = {}
  for _, vname in pairs(todel) do
    local found = false
    local uci_rulename = vname .. '_'

    for _, v in pairs(uci.cursor().get_all(fw)) do
      if mudutil.rule_match_name(uci_rulename, v) then
        log.info('Deleting: name=', v['name'] , ' .name=', v['.name'] )
        ucic.delete(fw, v['.name'])
        found = true
        resp_obj['rules'][vname] = "ok"
      end
    end
    if not found then
      resp_obj['rules'][vname] = "rnf"
      resp_obj['status'] = "err"
    else
      muddigger.remove(vname)
    end
  end

  ucic.commit(fw)
  restartFw()
  return resp_obj
end

mudrule.refreshrule = function(rulename, type, ips)
  -- rulename is same as in MUD file
  -- However, rulenames in UCI are suffixed with ip version and counter
  local ipv = type =='A' and 'ipv4' or 'ipv6'
  local uci_rulename = rulename .. '_' .. ipv .. '_'

  log.info("Refreshing rule", rulename, "for", ipv)

  local matching_rules = {}
  for _, v in pairs(uci.cursor().get_all(fw)) do
    if mudutil.rule_match_name(uci_rulename, v) then
      table.insert(matching_rules, v)
    end
  end

  if #matching_rules == 0 then
    log.warn("Could not find any rules matching ", uci_rulename .. '*')
    return
  end

  -- Mark matching rules for removal
  for _, rule in pairs(matching_rules) do
    ucic.delete(fw, rule['.name'])
  end
  -- Create new rule by duplicating existing one
  local rule = matching_rules[1]
  local direction = rule.src_mac ~= nil and 'from' or 'to'
  for i, v in ipairs(ips) do
    if direction == 'to' then
      rule.src_ip = v
    else
      rule.dest_ip = v
    end

    rule.name = rulename .. '_' .. ipv .. '_' .. i
    executeuci(rule)
  end

  ucic.commit(fw)
  restartFw()
end

mudrule.createdenyrule = function (mac_addr)
  --TODO use a dynamic name/src/dest for rule
  ace_info = {
    name = 'iot_toaster_deny', src = 'lan', dest = 'wan', proto='all',
    target = 'REJECT', dest_ip = '0.0.0.0/0',
    src_mac = mac_addr
  }

  executeuci(ace_info)

end

mudrule.createrule = function (acl, mac_addr, direction)

  local created_rules = {}

  if( acl.aces.ace) ~= nil then
    for k, v in pairs(acl.aces.ace) do

      url, proton, ipv = geturlproto(acl.type, v)
      local digtype = (ipv == 'ipv4' and 'A' or 'AAAA')

      ace_info = {
        --TODO we shouldnt rely on v.name it can be invalid for uci
        name = v.name, target = v.matches.actions.forwarding, proto=proton
      }

      if direction == 'to' then
        ace_info.src = mudconfig.wanzone
        ace_info.dest = mudconfig.iotszone
        ace_info.dest_mac = mac_addr
      else
        ace_info.src = mudconfig.iotszone
        ace_info.src_mac = mac_addr
        ace_info.dest = mudconfig.wanzone
      end

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
      recs = muddigger.dig(ace_info.name, url, digtype)

      if next(recs) then
        local basename = ace_info.name
        for i, ip in ipairs(recs) do
          if direction == 'to' then
            ace_info.src_ip = ip
          else
            ace_info.dest_ip = ip
          end

          ace_info.name = basename .. '_' .. ipv .. '_' .. i
          executeuci(ace_info)

          if created_rules[basename] == nil then
            created_rules[basename] = {}
          end
          table.insert(created_rules[basename], ace_info.name)
        end
      else
        log.warn('Skipping rule for: ', url, ' no ips retrieved.')
      end
    end
  else
    log.warn('no ace found in acl: ', acl.name)
  end
  return created_rules
end

return mudrule