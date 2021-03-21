local insert, unpack = table.insert, table.unpack
local modem = require('component').modem
local event = require('event')

local moonlink = {}

local PORT = 8431
local TIMER_INTERVAL = 30
local CODES = {
  ping = 'moonlink_ping',
  pong = 'moonlink_pong',
  send = 'moonlink_message'
}
local messages = {}
local tmp = {}
local moonlink_routes = {}

if not moonlink_timers then
  moonlink_timers = {}
  moonlink_listeners = {}
end

local function listener(...)
  local e = {...}
  if e[6] == CODES.pong then
    _, tmp = pcall(load(e[7]))
    if type(tmp) == 'table' then
      for address, jumps in pairs(tmp) do
        if (address and jumps and address ~= e[2])
        and (not moonlink_routes[address]
        or moonlink_routes[address][1] > jumps) then
          moonlink_routes[address] = {jumps + 1, e[3]}
        end
      end
    end
  elseif e[6] == CODES.ping then
    local result = 'return{'
    for address, value in pairs(moonlink_routes) do
      result = result .. '["' .. address .. '"]=' .. value[1] .. ','
    end
    modem.send(e[3], PORT, CODES.pong, result .. '["' .. e[2] .. '"]=0}')
  elseif e[6] == CODES.send then
    if e[2] == e[7] then
      event.push(unpack(e, 6))
    elseif moonlink_routes[e[7]] and moonlink_routes[e[7]] ~= e[2] then
      modem.send(moonlink_routes[e[7]][2], PORT, unpack(e, 6))
    else
      if not messages[e[7]] then
        messages[e[7]] = {}
      end
      insert(messages[e[7]], {unpack(e, 6)})
    end
  end
  for address in pairs(messages) do
    if moonlink_routes[address] then
      modem.send(moonlink_routes[address][2], PORT, unpack(messages[address]))
    end
    moonlink_routes[address] = {}
  end
end

moonlink.list = function()
  local list = {}
  for address in pairs(moonlink_routes) do
    insert(list, address)
  end
  return list
end

moonlink.ping = function()
  moonlink_routes = {}
  modem.broadcast(PORT, CODES.ping)
end

moonlink.connect = function(port)
  PORT = PORT or port
  modem.open(PORT)
  insert(moonlink_timers, event.timer(TIMER_INTERVAL, moonlink.ping))
  insert(moonlink_listeners, event.listen('modem_message', listener))
  moonlink.ping()
end

moonlink.disconnect = function()
  modem.close(PORT)
  if moonlink_listeners then
    for i = 1, #moonlink_listeners do
      event.cancel(moonlink_listeners[i])
      event.cancel(moonlink_timers[i])
    end
  else
    return false
  end
end

moonlink.send = function(address, ...)
  if moonlink_routes[address] then
    modem.send(moonlink_routes[address][2], PORT, CODES.send, address, ...)
  end
end

return moonlink