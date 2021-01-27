--[[
fedc ba98 7654 3210
1XXX XXXX XXXX XXXX literal
000X XXXX XXXX XXXX jump
001X XXXX XXXX XXXX conditional jump
010X XXXX XXXX XXXX call
011T TTTT XXXX RRDD alu
]]

min, max, insert, unpack = math.min, math.max, table.insert, table.unpack

local function int16(n)
  return n - (n >> 1) & 0xffff
end

local function uint16(n)
  return n & 0xffff
end

local function hash(str)
  local x, b = 0
  for i = 1, #str do
    b = str:sub(i, i):byte() & 63
    if i % 2 == 0 then
      x = x ~ b << 2
    else
      x = x ~ b << 7
    end
  end
  return (#str & 15) | x | ((str:sub(-1, -1):byte() & 1) << 14)
end

local CONST = {
  STACK_SIZE = 32,
  MEM_SIZE = 0x7FFF,
  [true] = 1,
  [false] = 0,
  INT_ADDRESS = 0x3000,
  DEVICE_LIST = 0x4000,
}

local CPU = {
  MEMORY = {},
  D_STACK = {},
  R_STACK = {},
  PC = 0, -- program counter
  T = 0, -- d_stack pointer
  R = 0, -- r_stack pointer
}

local function TD() -- top of d_stack
  return CPU.D_STACK[CPU.T]
end

local function ND() -- next value on d_stack
  return CPU.D_STACK[max(CPU.T - 1, 0)]
end

local function push(item)
  CPU.T = min(CPU.T + 1, CONST.STACK_SIZE)
  CPU.D_STACK[CPU.T] = item
end

local function pop()
  CPU.T = max(CPU.T - 1, 0)
  return CPU.D_STACK[CPU.T + 1]
end

local links = {devices = {}, methods = {}}

local function update_links()
  for address in pairs(component.list()) do
    if not links.devices[address] then
      local a = tonumber(address:sub(1, 4), 16)
      links.devices[address] = a
      links.devices[a] = address
    end
  end
end

local OP = {
  [0] = function() return TD() end,                 -- T
  function() return ND() end,                       -- N
  function() return uint16(TD() + ND()) end,        -- T + N
  function() return TD() & ND() end,                -- T and N
  function() return TD() | ND() end,                -- T or N
  function() return TD() ~ ND() end,                -- T xor N
  function() return ~TD() end,                      -- ~ T
  function() return CONST[TD() == ND()] end,        -- N == T
  function() return CONST[TD() > ND()] end,         -- T > N
  function() return ND() >> TD() end,               -- N rshift T
  function() return uint16(TD() - 1) end,           -- T - 1
  function() return CPU.R_STACK[CPU.R] end,         -- R
  function() return CPU.MEMORY[TD()] end,           -- [T]
  function() return uint16(ND() << TD()) end,       -- N lshift T
  function() return CPU.T end,                      -- depth
  function() return CONST[TD() > uint16(ND())] end, -- uN < T
  function()                                        -- INT
    local e = {computer.pullSignal(0.05)}
    if e then
      MEMORY[CONST.INT_ADDRESS] = hash(e[1]) | 0x8000
      local stack = {1, #e}
      local pos = CONST.INT_ADDRESS + 1
      for i = 2, #e do
        insert(stack, pos + 1)
        if type(e[i]) == 'string' then
          for j = 1, #e[i] do
            pos = pos + 1
            MEMORY[pos] = e[i]:sub(j, j):byte() | 0x8000
          end
        else
          pos = pos + 1
          MEMORY[pos] = e[i] | 0x8000
        end
      end
      for i = #stack, 1, -1 do
        push(stack[i])
      end
    else
      push(0)
    end
  end,
  function()                                        -- INV
    local address = pop()
    local m_hash = pop()
    local v_len = pop()
    local values = {}
    for i = 1, v_len do
      values[i] = pop()
    end
    if links.devices[address] then
      address = links.devices[address]
      if not links.methods[m_hash] then
        for m in pairs(component.proxy(address)) do
          local c_h = hash(m)
          links.methods[c_h] = m
        end
      end
      if links.methods[m_hash] then
        component.invoke(address, links.methods[m_hash], unpack(values))
      end
    end
  end,
  function()                                        -- UP
    update_links()
    local counter = 0
    for address in pairs(links.devices) do
      if type(address) == 'number' then
        CPU.MEMORY[CONST.DEVICE_LIST + 1 + counter] = address
        counter = counter + 1
      end
    end
    CONST.DEVICE_LIST = counter
  end
}

local function ALU(IR)
  if IR & 0x3 then -- DS +-
    CPU.T = min(CPU.T + 1, CONST.STACK_SIZE)
  elseif RS == 2 then
    CPU.T = max(CPU.T - 1, 0)
  end
  local RS = (IR & 0xC) >> 2
  if RS == 1 then -- RS +-
    CPU.R = min(CPU.R + 1, CONST.STACK_SIZE)
  elseif RS == 2 then
    CPU.R = max(CPU.R - 1, 0)
  end
  local result = 0
  if OP[IR & 0x1F00 >> 8] then -- OP
    result = OP[IR & 0x1F00 >> 8]()
  end
  if IR & 0x80 == 1 then -- R -> PC
    CPU.PC = CPU.R_STACK[CPU.R]
  end
  if IR & 0x40 == 1 then -- T -> N
    CPU.D_STACK[min(CPU.T + 1, 0)] = TD()
  end
  if IR & 0x20 == 1 then -- T -> R
    CPU.R_STACK[CPU.R] = TD()
  end
  if IR & 0x10 == 1 then -- N -> [T]
    CPU.MEMORY[TD()] = ND()
  end
  CPU.D_STACK[CPU.T] = result
end

local function decoder(IR)
  if IR & 0x8000 == 0x8000 then -- LIT
    CPU.T = min(CPU.T + 1, CONST.STACK_SIZE)
    D_STACK[CPU.T] = IR & 0x7FFF
    CPU.PC = min(CPU.PC + 1, CONST.MEM_SIZE)
  else
    local typ, IR = IR & 0xE0000, IR & 0x1FFF
    if typ == 0 then -- JMP
      CPU.PC = IR
    elseif typ == 0x2000 then -- JMPZ
      if TD() == 0 then
        CPU.PC = IR
      end
      CPU.T = CPU.T + 1 % CONST.STACK_SIZE
    elseif typ == 0x4000 then -- CALL
      CPU.R = CPU.R + 1 % CONST.STACK_SIZE
      CPU.R_STACK[CPU.R] = min(CPU.PC + 1, CONST.MEM_SIZE)
      CPU.PC = IR
    elseif typ == 0x6000 then -- ALU
      ALU(IR)
    end
  end
end

local function boot(image)
  -- init
  for i = 0, CONST.STACK_SIZE do
    D_STACK, R_STACK = 0, 0
  end
  for i = 0, CONST.MEM_SIZE do
    CPU.MEMORY = 0
  end
  -- load
  for i = 1, #image, 2 do
    CPU.MEMORY[i-1] = (image:sub(i, i):byte() << 8) + image:sub(i+1, i+1)
  end
  -- main loop
  while CPU.PC < CONST.MEM_SIZE do
    decoder(CPU.MEMORY[CPU.PC])
    CPU.PC = CPU.PC + 1
  end
end

local args = {...}

local function main()
  if #args ~= 1 then
    print('Usage: emulator <file.j1>')
    return
  end
  local f = io.open(filename)
  local data = f:read('*a')
  f:close()
  boot(data)
end
