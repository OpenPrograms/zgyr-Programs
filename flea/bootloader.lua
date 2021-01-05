local repository = 'https://raw.githubusercontent.com/OpenPrograms/zgyr-Programs/main/flea/'
local version = {'0.0.0.0'}
local invoke, list, proxy, filesystem = component.invoke, component.list, component.proxy

function add_component(name)
  name = list(name)()
  if name then
    return proxy(name)
  end
end

local gpu = add_component('gpu')
local modem = add_component('modem')
local tunnel = add_component('tunnel')
local eeprom = add_component('eeprom')
local internet = add_component('internet')
local redstone = add_component('redstone')

computer.getBootAddress = eeprom.getData
computer.setBootAddress = function(address)
  return eeprom.setData(address)
end

local function get_filesystem()
  local address = eeprom.getData()
  if address and list('filesystem')[address] then
    return proxy(address)
  end
  for address in list('filesystem') do
    if address ~= computer.tmpAddress() and not invoke(address, 'isReadOnly') then
      computer.setBootAddress(address)
      return proxy(address)
    end
  end
  error('filesystem not found')
end

function fs_write(path, mode, data)
  local handle = filesystem.open(path, mode)
  filesystem.write(handle, data)
  filesystem.close(handle)
end

function fs_read(path)
  local handle = filesystem.open(path)
  local buffer = ''
  repeat
    local data, reason = filesystem.read(handle, math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  filesystem.close(handle)
  return buffer
end

function internet_get(path)
  local _, request, reason = pcall(internet.request, path)
  local result, code, message, headers = ''
  if request then
    while not request.finishConnect() do
      computer.pullSignal(1)
    end
    code, message, headers = request.response()
    while true do
      if not code then
        break
      end
      local data, reason = request.read()
      if not data then
        request.close()
        break
      elseif #data > 0 then
        result = result..data
      end
    end
    if tonumber(headers['Content-Length'][1]) == #result then
      return result
    end
  end
end

function dofile(filename)
  local program, reason = load(fs_read(filename), '=' .. filename)
  if not program then
    return error(reason .. ':' .. filename, 0)
  end
  return program()
end

local function update()
  if internet then
    if filesystem.exists('/version.lua') then
      version = dofile('/version.lua')
    end
    local _, new_version = pcall(load(internet_get(repository .. 'version.lua')))
    if new_version and new_version[1] ~= version[1] then
      for i = 1, #new_version.files do
        local file = internet_get(repository .. new_version.files[i])
        if file then
          fs_write('/' .. new_version.files[i], 'w', file)
        end
      end
      eeprom.set(fs_read('/bootloader.lua'))
      computer.shutdown(true)
    end
  end
end

local function main()
  if modem then
    modem.setWakeMessage('')
    modem.setStrength(400)
    modem.open(1)
  end
  if tunnel then
    tunnel.setWakeMessage('')
  end
  if redstone then
    redstone.setWakeThreshold(1)
  end
  if gpu then
    gpu.bind(list('screen')(), true)
  end
  filesystem = get_filesystem()
  update()
  computer.beep(880, 0.05)
  dofile('/init.lua')
end

main()