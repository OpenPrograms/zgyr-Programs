--[[
fedc ba98 7654 3210
1XXX XXXX XXXX XXXX literal
000X XXXX XXXX XXXX jump
001X XXXX XXXX XXXX conditional jump
010X XXXX XXXX XXXX call
011T TTTT XXXX RRDD alu
]]

local function int16(n)
  return n - (n >> 1) & 0xffff
end

local function uint16(n)
  return n & 0xffff
end

local CONST = {
  STACK_SIZE = 32,
  MEM_SIZE = 0x8000,
}

local CPU = {
  MEMORY = {},
  D_STACK = {},
  R_STACK = {},
  PC = 0, -- program counter
  T = 0, -- d_stack pointer
  R = 0, -- r_stack pointer
}
