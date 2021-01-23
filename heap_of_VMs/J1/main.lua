--[[
fedc ba98 7654 3210
1XXX XXXX XXXX XXXX literal
000X XXXX XXXX XXXX jump
001X XXXX XXXX XXXX conditional jump
010X XXXX XXXX XXXX call
011T TTTT XXXX RRDD alu
]]

min, max = math.min, math.max

local function int16(n)
  return n - (n >> 1) & 0xffff
end

local function uint16(n)
  return n & 0xffff
end

local CONST = {
  STACK_SIZE = 32,
  MEM_SIZE = 0x8000,
  true = 1,
  false = 0,
}

local CPU = {
  MEMORY = {},
  D_STACK = {},
  R_STACK = {},
  PC = 0, -- program counter
  T = 0, -- d_stack pointer
  R = 0, -- r_stack pointer
}

local function init()
  for i = 0, CONST.STACK_SIZE do
    D_STACK, R_STACK = 0, 0
  end
  for i = 0, CONST.MEM_SIZE do
    CPU.MEMORY = 0
  end
end

local function TD() -- top of d_stack
  return CPU.D_STACK[CPU.T]
end

local function ND() -- next value on d_stack
  return CPU.D_STACK[CPU.T - 1 % CONST.STACK_SIZE]
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
}

local function ALU(IR)
  if IR & 0x3 then -- DS +-
    CPU.D_STACK[CPU.T] = min(TD() + 1, CONST.STACK_SIZE)
  elseif RS == 2 then
    CPU.D_STACK[CPU.T] = max(TD() - 1, 0)
  end
  local RS = (IR & 0xC) >> 2
  if RS == 1 then -- RS +-
    CPU.R_STACK[CPU.R] = min(CPU.R_STACK[CPU.R] + 1, CONST.STACK_SIZE)
  elseif RS == 2 then
    CPU.R_STACK[CPU.R] = max(CPU.R_STACK[CPU.R] - 1, 0)
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
