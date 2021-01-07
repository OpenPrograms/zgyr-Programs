local insert, unpack = table.insert, table.unpack
local modem = require('component').modem
local event = require('event')

local moonlink = {}

local S_PORT, D_PORT = 8431, 8432
local TIMER_INTERVAL = 12
local CODES = {
  ping = 'moonlink_ping',
  pong = 'moonlink_pong',
  send = 'moonlink_message'
}
local tmp = {}
if not _G.moonlink_routes then
  _G.moonlink_routes = {}
  _G.moonlink_timers = {}
  _G.moonlink_listeners = {}
end

local function listener(...)
  local e = {...}
  if e[4] == S_PORT then
    if e[6] == CODES.pong then
      _, tmp = pcall(load(e[7]))
      if type(tmp) == 'table' then
        for address, jumps in pairs(tmp) do
          if address and jumps and ((not _G.moonlink_routes[address]
          or _G.moonlink_routes[address][1] > jumps)
          and address ~= e[2]) then
            _G.moonlink_routes[address] = {jumps + 1, e[3]}
          end
        end
      end
    elseif e[6] == CODES.ping then
      local result = 'return{'
      for address, value in pairs(_G.moonlink_routes) do
        result = result .. '["' .. address .. '"]=' .. value[1] .. ','
      end
      modem.send(e[3], S_PORT, CODES.pong, result .. '["' .. e[2] .. '"]=0}')
    end
  elseif e[4] == D_PORT and e[6] == CODES.send then
    if e[2] == e[6] then
      event.push(unpack(e, 6))
    elseif _G.moonlink_routes[e[7]] then
      modem.send(_G.moonlink_routes[e[7]][2], unpack(e, 6))
    end
  end
end

moonlink.list = function()
  local list = {}
  for address in pairs(_G.moonlink_routes) do
    insert(list, address)
  end
  return list
end

moonlink.ping = function()
  _G.moonlink_routes = {}
  modem.broadcast(S_PORT, CODES.ping)
end

moonlink.connect = function()
  modem.open(S_PORT)
  modem.open(D_PORT)
  insert(_G.moonlink_timers, event.timer(TIMER_INTERVAL, moonlink.ping))
  insert(_G.moonlink_listeners, event.listen('modem_message', listener))
  moonlink.ping()
end

moonlink.disconnect = function()
  modem.close(S_PORT)
  modem.close(D_PORT)
  if _G.moonlink_listeners then
    for i = 1, #_G.moonlink_listeners do
      event.cancel(_G.moonlink_listeners[i])
      event.cancel(_G.moonlink_timers[i])
    end
  else
    return false
  end
end

moonlink.send = function(address, ...)
  if _G.moonlink_routes[address] then
    modem.send(_G.moonlink_routes[address][2], D_PORT, CODES.send, address, ...)
  end
end

return moonlink