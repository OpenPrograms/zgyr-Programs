local bit32 = require('bit32')
local floor, insert = math.floor, table.insert
local rrotate, lrotate = bit32.rrotate, bit32.lrotate

MEM = {}
DCPU16 = {}
DCPU16.cycles = 0
DCPU16.interrupts = {}
DCPU16.DEV = {}
local interruptsEnabled = false

REG = {
  A = 0x10000, B = 0x10001,
  C = 0x10002, X = 0x10003,
  Y = 0x10004, Z = 0x10005,
  I = 0x10006, J = 0x10007,
  SP = 0x1001b, PC = 0x1001c,
  EX = 0x1001d, IA = 0x1001e
}

local function counter(c)
  DCPU16.cycles = DCPU16.cycles + c
end

local function int16(n)
  return n - (n >> 1) & 0xffff
end

local function uint16(n)
  return n & 0xffff
end

for i = 0, 0x1001e do
  MEM[i] = 0
end

for i = 0x1001f, 0x1003e do -- fill literals
  MEM[i] = i - 0x10020
end

local function step()
  MEM[REG.PC] = MEM[REG.PC] + 1
  counter(1)
end

local function nextWord()
  local word = MEM[REG.PC]
  step()
  return word
end

local VALUES = {
  [0x18] = function(f)
    if f then
      local res = MEM[REG.SP]
      MEM[REG.SP] = uint16(MEM[REG.SP] + 1)
      return res
    else
      MEM[REG.SP] = uint16(MEM[REG.SP] - 1)
      return MEM[REG.SP]
    end
  end,
  [0x19] = function() return MEM[REG.SP] end,
  [0x1a] = function() return MEM[REG.SP] + MEM[nextWord()] end,
  [0x1b] = function() return REG.SP end,
  [0x1c] = function() return REG.PC end,
  [0x1d] = function() return REG.EX end,
  [0x1e] = function() return MEM[nextWord()] end,
  [0x1f] = function() return nextWord() end
}

for i = 0, 7 do
  VALUES[i] = function() return 0x10000 + i end
  VALUES[i + 8] = function() return MEM[0x10000 + i] end
  VALUES[i + 16] = function() return MEM[0x10000 + i] + MEM[nextWord()] end
end

for i = 0x1001f, 0x1003e do
  insert(VALUES, function() return i end)
end

local sOPCODES = {
  function(a) -- jsr +
    MEM[REG.SP] = uint16(MEM[REG.SP] - 1)
    MEM[MEM[REG.SP]] = MEM[REG.PC]
    MEM[REG.PC] = MEM[a]
    counter(3)
  end,

  [0x08] = function(a) -- int
    insert(DCPU16.interrupts, MEM[a])
    if #DCPU16.interrupts > 256 then
      error('Too many interrupts')
    end
    counter(4)
  end,

  [0x09] = function(a) MEM[REG.IA] = MEM[a] counter(1) end, -- iag -
  [0x0a] = function(a) MEM[a] = MEM[REG.IA] counter(1) end, -- ias -
  [0x0b] = function(a) -- rfi
    interruptsEnabled = false
    MEM[REG.A] = MEM[REG.SP]
    MEM[REG.PC] = uint16(MEM[REG.SP] + 1)
    MEM[REG.SP] = uint16(MEM[REG.SP] + 2)
    counter(3)
  end,

  [0x0c] = function(a) -- iaq
    if MEM[a] == 0 then
      interruptsEnabled = false
    else
      interruptsEnabled = true
    end
    counter(2)
  end,
  [0x10] = function(a) MEM[a] = #DEV counter(2) end, -- hwn

  [0x11] = function(a) -- hwq
    local device = DCPU16.DEV[MEM[a]]
    if device then
      MEM[REG.A] = uint16(device.id)
      MEM[REG.B] = uint16(device.id >> 16)
      MEM[REG.C] = uint16(device.version)
      MEM[REG.X] = uint16(device.manufacturer)
      MEM[REG.Y] = uint16(device.manufacturer >> 16)
    end
    counter(4)
  end,

  [0x11] = function(a) -- hwi
    local device = DCPU16.DEV[MEM[a]]
    if device then
      device.interrupt()
    end
    counter(4)
  end
}

local OPCODES = {
  [0] = function(b, a) b = MEM[b] + 1 if sOPCODES[b] then sOPCODES[b](a) end end,

  function(b, a) MEM[b] = uint16(MEM[a]) counter(1) end, -- set

  function(b, a) -- add
    local res1 = MEM[b] + MEM[a]
    local res2 = uint16(res1)
    if res1 ~= res2 then
      MEM[REG.EX] = 1
    else
      MEM[REG.EX] = 0
    end
    MEM[b] = res2
    counter(2)
  end,

  function(b, a) -- sub
    local res1 = MEM[b] - MEM[a]
    local res2 = uint16(res2)
    if res1 ~= res2 then
      MEM[REG.EX] = 0xffff
    else
      MEM[REG.EX] = 0
    end
    MEM[b] = res2
    counter(2)
  end,

  function(b, a) -- mul
    local res1 = MEM[b] * MEM[a]
    MEM[REG.EX] = uint16(res1 >> 16)
    MEM[b] = uint16(res2)
    counter(2)
  end,

  function(b, a) -- mli
    local res1 = int16(MEM[b]) * int16(MEM[a])
    MEM[REG.EX] = uint16(res1 >> 16)
    MEM[b] = uint16(res2)
    counter(2)
  end,

  function(b, a) -- div
    if MEM[a] == 0 then
      MEM[REG.EX], MEM[b] = 0, 0
    else
      MEM[REG.EX] = uint16(floor((MEM[b] << 16) / MEM[a]))
      MEM[b] = uint16(floor(MEM[b] / MEM[a]))
    end
    counter(3)
  end,

  function(b, a) -- dvi
    if MEM[a] == 0 then
      MEM[REG.EX], MEM[b] = 0, 0
    else
      MEM[REG.EX] = uint16(floor((MEM[b] << 16) / MEM[a]))
      MEM[b] = uint16(floor(int16(MEM[b]) / int16(MEM[a])))
    end
    counter(3)
  end,

  function(b, a) -- mod
    if MEM[a] == 0 then
      MEM[b] = 0
    else
      MEM[b] = uint16(MEM[b] % MEM[a])
    end
    counter(3)
  end,

  function(b, a) -- mdi
    if MEM[a] == 0 then
      MEM[b] = 0
    else
      MEM[b] = uint16(int16(MEM[b]) % int16(MEM[a]))
    end
    counter(3)
  end,

  function(b, a) MEM[b] = MEM[b] & MEM[a] counter(1) end, -- and

  function(b, a) MEM[b] = MEM[b] | MEM[a] counter(1) end, -- bor

  function(b, a) MEM[b] = MEM[b] ~ MEM[a] counter(1) end, -- xor
----------------------------------------------------------
  function(b, a) -- shr
    MEM[REG.EX] = uint16((MEM[b] << 16) >> MEM[b])
    MEM[b] = uint16(MEM[b] >> MEM[a])
    counter(1)
  end,
  
  function(b, a) -- asr
    -- sets b to b>>a, sets EX to ((b<<16)>>>a)&0xffff 
    MEM[REG.EX] = uint16((MEM[b] << 16) >> MEM[a])
    MEM[b] = uint16(int16(MEM[b]) >> MEM[a])
    counter(1)
  end,

  function(b, a) -- shl
    MEM[REG.EX] = uint16((MEM[b] << MEM[a]) >> 16)
    MEM[b] = uint16(MEM[b] << MEM[a])
    --MEM[REG.EX] = uint16(rrotate(lrotate(MEM[b], MEM[a]), 16))
    --MEM[b] = uint16(lrotate(MEM[b], MEM[a]))
    counter(1)
  end,
----------------------------------------------------------
  function(b, a) if MEM[b] & MEM[a] == 0 then step() end counter(2) end, --ifb

  function(b, a) if MEM[b] & MEM[a] ~= 0 then step() end counter(2) end, --ifc

  function(b, a) if MEM[b] ~= MEM[a] then step() end counter(2) end, --ife

  function(b, a) if MEM[b] == MEM[a] then step() end counter(2) end, --ifn

  function(b, a) if MEM[b] < MEM[a] then step() end counter(2) end, --ifg

  function(b, a) if int16(MEM[b]) < int16(MEM[a]) then step() end counter(2) end, --ifa

  function(b, a) if MEM[b] > MEM[a] then step() end counter(2) end, --ifl

  function(b, a) if int16(MEM[b]) > int16(MEM[a]) then step() end counter(2) end, --ifu

  [0x1a] = function(b, a) -- adx
    a = MEM[b] + MEM[a] + MEM[REG.EX]
    MEM[b] = uint16(a)
    if a ~= MEM[b] then
      MEM[REG.EX] = 1
    else
      MEM[REG.EX] = 0
    end
    counter(3)
  end,

  [0x1b] = function(b, a) -- sbx
    a = MEM[b] - MEM[a] + MEM[REG.EX]
    MEM[b] = uint16(a)
    if a ~= MEM[b] then
      MEM[REG.EX] = 0xffff
    else
      MEM[REG.EX] = 0
    end
    counter(3)
  end,

  [0x1e] = function(b, a) -- sti
    MEM[b] = MEM[a]
    MEM[REG.I] = uint16(MEM[REG.I] + 1)
    MEM[REG.J] = uint16(MEM[REG.J] + 1)
    counter(2)
  end,

  [0x1f] = function(b, a) -- std
    MEM[b] = MEM[a]
    MEM[REG.I] = uint16(MEM[REG.I] - 1)
    MEM[REG.J] = uint16(MEM[REG.J] - 1)
    counter(2)
  end
}

DCPU16.load_raw = function(str, address)
  for i = 1, #str, 2 do
    MEM[address] = (str:sub(i, i):byte() << 8) & str:sub(i+1, i+1):byte()
  end
end

DCPU16.step = function()
  local word = MEM[MEM[REG.PC]]
  step()
  if word ~= 0 then
    local A, B, O = (word >> 10) & 63, (word >> 5) & 31, word & 31
    if B < 0x1f then
      B, A = VALUES[B](), VALUES[A](true)
      OPCODES[O](B, A)
    end
  end
end

return DCPU16