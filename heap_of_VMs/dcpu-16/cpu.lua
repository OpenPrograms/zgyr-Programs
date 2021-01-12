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
