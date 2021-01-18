min, max, sub, char, len = math.min, math.max, unicode.sub, unicode.char, unicode.len
list, proxy, gpu, screen = component.list, component.proxy
block = char(0x2588)

function add_component(name)
  name = list(name)()
  if name then
    return proxy(name)
  end
end

-- tty
gpu = add_component('gpu')
gpu.bind(({list('screen')()})[1])

local W, H = gpu.getViewport()
local X, Y = 1, 1

local line = ''
local isReading = true

function clearTTY() gpu.fill(1, 1, W, H, ' ') end

function setX(new)
  X = min(max(new, 1), W)
end

function writeLine(block)
  gpu.fill(1, Y, W, 1, ' ')
  gpu.set(1, Y, sub(line, 1, X - 1) .. block .. sub(line, X))
end

keys = {
  [14] = function()
    if X > 1 then
      setX(X - 1)
      line = sub(line, 1, X - 1) .. sub(line, X + 1)
    end
  end,
  [28] = function() isReading = false end,
  [199] = function() setX(1) end,
  [203] = function() setX(X-1) end,
  [205] = function() setX(X+1) end,
  [207] = function() setX(len(line) + 1) end,
  [211] = function()
    if X <= len(line) then
      line = sub(line, 1, X - 1) .. sub(line, X + 1)
    end
  end,
}

function readLine()
  writeLine(block)
  while isReading do
    local event = {computer.pullSignal(0.05)}
    if event and event[1] == 'key_down' then
      if keys[event[4]] then
        keys[event[4]]()
      else
        if event[3] ~= 0 and X < W then
          line = sub(line, 1, X) .. char(event[3]) .. sub(line, X)
          setX(X + 1)
        end
      end
      writeLine(block)
    end
  end
  writeLine('')
  if Y == H then
    gpu.copy(1, 1, W, H, 0, -1)
    gpu.fill(1, H, 1, 1, ' ')
  end
  Y = min(Y + 1, H)
  setX(1)
  line = ''
end