min, max, sub, char, len = math.min, math.max, unicode.sub, unicode.char, unicode.len
list, proxy, gpu, screen = component.list, component.proxy
block = char(0x2588)

function add_component(name)
  name = list(name)()
  if name then
    return proxy(name)
  end
end

function round(n)
  return math.floor(n + 0.5)
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

function write(text)
  gpu.set(X + 1, Y, text)
  setX(X+len(text))
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

-- vm

CONST = {
  [true] = 1,
  [false] = 0
}

STACK_SIZE = 1024
MEMORY = {n = 0}
E_STACK = {n = 0}
D_STACK = {n = 0}
CHAR, POS = '', 0
source, offset, tracing = 0, 0, 0

function err(n)
  D_STACK.n = 0
end

function push(value)
  if D_STACK.n < STACK_SIZE then
    D_STACK.n = D_STACK.n + 1
    D_STACK[D_STACK.n] = value
  else
    err(2)
  end
end

function pop()
  if D_STACK.n >= 0 then
    D_STACK.n = D_STACK.n - 1
    return D_STACK[D_STACK.n + 1]
  else
    err(3)
  end
end

function getChar()
  if POS < #line then
    POS = POS + 1
    CHAR = sub(line, POS, POS)
  else
    err(1)
  end
end

function skipString()
  local temp
  while CHAR ~= '"' do
    getChar()
  end
end

local functions = {
  ['2x'] = 'push(pop()^2)',
  ['4th'] = 'push(pop()^4)',
  ['4thrt'] = 'push(math.sqrt(math.sqrt(pop())))',
  ['10x'] = 'push(pop()^10)',
  ['abs'] = 'push(math.abs(pop()))',
}

local opcodes = {
  ['_'] = 'push(-pop())',
  ['+'] = 'push(pop()+pop())',
  ['-'] = 'a=pop()push(pop()-a)',
  ['*'] = 'push(pop()*pop())',
  ['/'] = [[a = pop()
  if a ~= 0 then
    push(pop() / a)
  else
    err(4)
  end]],
  ['\\'] = [[a = pop()
  if a ~= 0 then
    push(pop() % a)
  else
    err(5)
  end]],
  ['?'] = '',
  ['!'] = '',
  ['"'] = [[repeat
    getChar()
    if CHAR == '!' then
      output = output .. '\n'
    elseif CHAR ~= '"'
      output = output .. char(CHAR)
    end
  until CHAR == '"']],
  [':'] = 'a = pop() MEMORY[round(a)] = pop',
  ['.'] = 'push(MEMORY[round(pop())])',
  ['<'] = 'a = pop push(CONST[pop() < a])',
  ['='] = 'push(CONST[pop() < pop()])',
  ['>'] = 'a = pop push(CONST[pop() > a])',
  ['['] = '',
  ['|'] = 'skip("[","]")',
  ['('] = 'push_e(loop)',
  [')'] = 'POS=E_STACK[E_STACK.n].POS',
  ['^'] = 'if pop() <= 0 then pop_e() skip("(",")")',
  ['#'] = '',
  ['@'] = '',
  ['%'] = '',
  [';'] = 'pop_e()',
  ['\''] = 'getChar() push(tonumber(CHAR))',
  ['{'] = 'tracing = 1',
  ['}'] = 'tracing = 0',
  ['&'] = ''
  
}

for i in pairs(opcodes) do opcodes[i] = load(opcodes[i]) end

function interpret()
  offset, POS = 0, 0
  local chn = 0
  while POS < #line do
    getChar()
    if tonumber(CHAR) then
      temp = line:sub(POS):match('(%d*%.?%d+)')
      POS = POS + #temp
      push(tonumber(temp))
    else
      chn = CHAR:byte()
      if chn >= 65 and chn <= 90 then
        push(chn - 65)
      elseif chn >= 97 and chn <= 122 then
        push(chn - 97 + offset)
      else
        if opcodes[CHAR] then
          opcodes[CHAR]()
        end
      end
    end
  end
end

interpret()
print(pop(D_STACK))