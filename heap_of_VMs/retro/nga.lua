min, max = math.min, math.max
STACK_SIZE = 1024
MEMORY = {n = 0}
ADDRESS = {n = 0}
STACK = {n = 0}
NUM_DEVICES = 1
INT_MIN, INT_MAX = -2147483648, 2147483647

local deb_opcodes = {
  [0] = 'nop',
  'lit', 'dup',
  'drop', 'swap',
  'push', 'pop',
  'jump', 'call',
  'ccal', 'ret',
  'eq', 'neq',
  'lt', 'gt',
  'fetch', 'store',
  'add', 'sub',
  'mul', 'divmod',
  'and', 'or',
  'xor', 'shift',
  'zret', 'halt',
  'ioe', 'ioq', 'ioi'
}

function push(stack, value)
  stack.n = (stack.n + 1) % 128
  stack[stack.n] = value
end

function pop(stack)
  stack.n = min(stack.n-1, 0)
  return stack[stack.n]
end

instructions = {
  [0] = '',                                         -- nop
  'push(STACK, MEMORY[MEMORY.n])',                  -- lit
  'push(STACK, STACK[STACK.n])',                    -- dup
  'STACK.n = max(STACK.n-1, 0)',                    -- drop
  [[STACK[STACK.n], STACK[STACK.n-1] =
  STACK[STACK.n-1], STACK[STACK.n] ]],              -- swap
  'push(ADDRESS, pop(STACK))',                      -- push
  'push(STACK, pop(ADDRESS))',                      -- pop
  'MEMORY.n = pop(STACK)',                          -- jump
  'push(ADDRESS, MEMORY.n) MEMORY.n = pop(STACK)',  -- call
  [[local target = pop(STACK)
    if pop(STACK) ~= 0 then
      push(ADDRESS, MEMORY.n)
      MEMORY.n = target - 1
    end
  end]],                                            -- ccall
  'MEMORY.n = pop(ADDRESS)',                        -- return
  [[if pop(STACK) == pop(STACK) then
    push(STACK, -1)
  else
    push(STACK, 0)
  end]],                                            -- eq
  [[if pop(STACK) ~= pop(STACK) then
    push(STACK, -1)
  else
    push(STACK, 0)
  end]],                                            -- neq
  [[if pop(STACK) > pop(STACK) then
    push(STACK, -1)
  else
    push(STACK, 0)
  end]],                                            -- lt
  [[if pop(STACK) > pop(STACK) then
    push(STACK, -1)
  else
    push(STACK, 0)
  end]],                                            -- gt
  [[local target = pop(STACK)
  if target == -1 then
    push(STACK, STACK.n)
  elseif target == -2 then
    push(STACK, ADDRESS.n)
  elseif target == -3 then
    push(STACK, #MEMORY)
  elseif target == -4 then
    push(STACK, INT_MIN)
  elseif target == -5 then
    push(STACK, INT_MAX)
  else
    push(STACK, MEMORY[target])
  end]],                                            -- fetch
  'MEMORY[pop(STACK)] = pop(STACK)',                -- store
  'STACK[STACK.n-1] = pop(STACK)+STACK[STACK.n-1]', -- add
  'STACK[STACK.n-1] = STACK[STACK.n-1]-pop(STACK)', -- sub
  'STACK[STACK.n-1] = STACK[STACK.n-1]*pop(STACK)', -- mul
  [[local a, b = pop(STACK), pop(STACK)
  push(STACK, b % a)
  push(STACK, (b + (a % b)) % b)]],                 -- divmod
  'STACK[STACK.n-1] = STACK[STACK.n-1]&pop(STACK)', -- and
  'STACK[STACK.n-1] = STACK[STACK.n-1]|pop(STACK)', -- or
  'STACK[STACK.n-1] = STACK[STACK.n-1]~pop(STACK)', -- xor
  [[local a, b = pop(STACK), pop(STACK)
  if x < 0 then
    push(STACK, b << (x * -1))
  else
    push(STACK, b >> x)
  end]],                                            -- shift
  [[if STACK[STACK.n] == 0 then
    pop(STACK)
    MEMORY.n = pop(ADDRESS)
  end]],                                            -- zret
  'MEMORY.n = #MEMORY',                             -- halt
  'push(STACK, NUM_DEVICES)',                       -- io enumerate
  'print("ioq")',                                   -- io query
  'print("ioi")'                                    -- io interact
}

for i = 0, #instructions do instructions[i] = load(instructions[i]) end

function checkStack()
  if STACK.n < 0 or ADDRESS.n < 0 or
  STACK.n > STACK_SIZE or ADDRESS.n > STACK_SIZE then
    STACK.n = 0
    MEMORY.n = 0
    ADDRESS.n = 0
  end
end

function extract_string(at)
  local s = ''
  while MEMORY[at] ~= 0 do
    s = s + char(MEMORY[at])
    at = at + 1
  end
  return s
end

function inject_string(s, to)
  for c = 1, #s do
    MEMORY[to] = s:sub(c, c):byte()
    to = to + 1
  end
  MEMORY[to] = 0
end

function fs_read(name)
  local file = io.open(name)
  local data = file:read('a*')
  file:close()
  return data
end

function loadImage()
  local image = loadfile('image.lua')()
  for i = 1, #image do
    MEMORY[i-1] = image[i]
  end
--[[
  local image, cell = fs_read('ngaImage')
  for i = 1, #image, 4 do
    cell = image:sub(i, i):byte()
    cell = cell + (image:sub(i+1, i+1):byte() << 8)
    cell = cell + (image:sub(i+2, i+2):byte() << 16)
    cell = cell + (image:sub(i+3, i+3):byte() << 24)
    MEMORY[i-1] = cell
  end
]]
end

function lookup(name)
  local dt, i = 0, MEMORY[2]
  local target = ''
  while MEMORY[i] ~= 0 and i ~= 0 do
    target = extract_string(i + 3)
    if target == name then
      dt, i = i, 0
    else
      i = MEMORY[i]
    end
  end
  return dt
end

function validate_opcode(opcode)
  local valid, current = true
  for i = 1, 4 do
    current = opcode & 0xFF
    if not (current >= 0 and current <= 29) then
      valid = false
    end
    opcode = opcode >> 8
  end
  return valid
end

function process(opcode)
  opcode = opcode or 0
  if validate_opcode(opcode) then
    for i = 1, 4 do
      if opcode & 0xFF ~= 0 then
        print(deb_opcodes[opcode & 0xFF])
        instructions[opcode & 0xFF]()
        opcode = opcode >> 8
        --checkStack()
      end
    end
  else
    if opcode >= 0 and opcode <= 29 then
      print(deb_opcodes[opcode & 0xFF])
      instructions[opcode]()
      --checkStack()
    end
  end
end

function execute(word, notfound)
  if ADDRESS.n == 0 then
    push(ADDRESS, 0)
  else
    push(ADDRESS, -1)
    push(ADDRESS, MEMORY.n)
  end
  MEMORY.n = word
  while MEMORY.n < 1000000 do
    if ADDRESS[ADDRESS.n] == 1 then
      pop(ADDRESS)
      MEMORY.n = ADDRESS[ADDRESS.n]
      return
    end
    if MEMORY.n == CASHED['s:eq?'] then
      local a = extract_string(pop(STACK))
      local b = extract_string(pop(STACK))
      if a == b then
        push(STACK, -1)
      else
        push(STACK, 0)
      end
      MEMORY.n = pop(ADDRESS)
    elseif MEMORY.n == CASHED['d:lookup'] then
      local name = extract_string(pop(STACK))
      local header = find_entry(name)
      push(STACK, header)
      MEMORY[CASHED['d:lookup'] - 20] = header
      MEMORY.n = pop(ADDRESS)
    elseif MEMORY.n == CASHED['s:to-number'] then
      local n = extract_string(pop(STACK))
      push(STACK, tonumber(n))
      MEMORY.n = pop(ADDRESS)
    elseif MEMORY.n == CASHED['s:length'] then
      local n = #extract_string(pop(STACK))
      push(STACK)
      MEMORY.n = pop(ADDRESS)
    else
      if MEMORY.n == notfound then
        error('ERROR: word not found!', 0)
      end
      if MEMORY.n == CASHED['d:add-header'] then
        DICT[extract_string(STACK[3])] = MEMORY[3]
        local opcode = MEMORY[MEMORY.n]
        I0 = opcode & 0xff
        I1 = (opcode >> 8) & 0xff
        I2 = (opcode >> 16) & 0xff
        I3 = (opcode >> 24) & 0xff
      end
    end
    if ADDRESS.n == 0 then
      MEMORY.n = 2000000
    end
    MEMORY.n = MEMORY.n + 1
  end
end

local function _init()
  for i = 0, STACK_SIZE do
    STACK[i], ADDRESS[i] = 0, 0
  end
  for i = 0, 100 do
    MEMORY[i] = 0
  end
  loadImage()
end

local function run()
  local done, line = false
  while not done do
    line = input('\nOK>')
    if line == 'bye' then
      done = true
    else
      for token in line:gmatch('([^ ]+)') do
        inject_string(token, 1024)
        push(STACK, 1024)
        execute(CASHED['interpreter'], CASHED['not_found'])
      end
    end
  end
end
--[[
_init()
while MEMORY.n < 1000000 do
  if ADDRESS.n == 0 then
    push(ADDRESS, 0)
  else
    push(ADDRESS, -1)
    push(ADDRESS, MEMORY.n)
  end
  process(MEMORY[MEMORY.n])
  print(MEMORY.n, MEMORY[MEMORY.n], STACK.n, ADDRESS.n)
  os.sleep(0)
  MEMORY.n = MEMORY.n + 1
end
]]