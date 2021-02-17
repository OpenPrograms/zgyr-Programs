min, max = math.min, math.max
sub, char, len, upper = unicode.sub, unicode.char, unicode.len, unicode.upper
insert, tonumber, tostring = table.insert, tonumber, tostring
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

function clearTTY() gpu.fill(1, 1, W, H, ' ') X, Y = 1, 1 end

function setX(new)
  X = min(max(new, 1), W)
end

function writeLine(block)
  gpu.fill(1, Y, W, 1, ' ')
  gpu.set(1, Y, sub(line, 1, X - 1) .. block .. sub(line, X))
end

function write(text)
  text = tostring(text)
  for i = 1, len(text) do
    local c = sub(text, i, i)
    if c == '\a' then
      computer.beep(440, 0.05)
    elseif c == '\b' then
      X = setX(X - 1)
    elseif c == '\t' then
      X = setX(X + 4)
    elseif c == '\r' then
      X = 1
    elseif c == '\n' then
      Y = min(Y + 1, H)
    else
      gpu.set(X, Y, c)
      X = X + 1
    end
  end
end

keys = {
  [88] = function() computer.shutdown(true) end,
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
  line = ''
  writeLine(block)
  while isReading do
    local event = {computer.pullSignal(0.05)}
    if event and event[1] == 'key_down' then
      if keys[event[4]] then
        keys[event[4]]()
      else
        if event[3] ~= 0 and X < W then
          line = sub(line, 1, X-1) .. char(event[3]) .. sub(line, X)
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
  line = line .. '\n'
end

-- vm
CONST = {
  [true] = 1,
  [false] = 0
}


function err(text)
  write('Error: ' .. text .. '\n\r')
end

function push(v)
  STACK.n = STACK.n + 1
  STACK[STACK.n] = v
end

function pop()
  STACK.n = STACK.n - 1
  if STACK.n > 1 then
    return STACK[STACK.n+1]
  else
    err('Stack underflow')
  end
end

STACK = {n=1}
WORDS = {
  [':'] = 'def=true',
  [';'] = 'def,name=nil,nil',
  ['DUP'] = 'a=pop()push(a)push(a)',
  ['DROP'] = 'pop()',
  ['EMIT'] = 'write(char(pop()))',
  ['+'] = 'push(pop()+pop())',
  ['-'] = 'a,b=pop(),pop()push(a-b)',
  ['*'] = 'push(pop()*pop())',
  ['/'] = 'a,b=pop(),pop()push(a/b)',
  ['='] = 'push(CONST[pop()==pop()])',  
}

function interpret(word)
  word = tonumber(word) or upper(word)
  if type(word) == 'number' then
    push(word)
  else
    if def and not name then
      name = word
      WORDS[name] = {}
    elseif def and name then
      if word ~= ';' then
        insert(WORDS[name], word)
      end
    else
      if type(WORDS[word]) == 'table' then
        for i = 1, #WORDS[word] do
          interpret(WORDS[word][i])
        end
      else
        pcall(load(WORDS[word]))
      end
    end
  end
end

function main()
  clearTTY()
  while true do
    readLine()
    local word = ''
    for i = 1, len(line) do
      local c = sub(line, i, i)
      if c == ' ' or c == '\n' then
        interpret(word)
        word = ''
      else
        word = word .. c
      end
    end
    isReading = true
  end
end
