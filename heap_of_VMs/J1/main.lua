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

local function decoder(IR)
  if IR & 0x8000 == 0x8000 then -- LIT
    CPU.T = CPU.T + 1 % CONST.STACK_SIZE
    D_STACK[CPU.T] = IR & 0x7FFF
    CPU.PC = CPU.PC + 1 % CONST.MEM_SIZE
  else
    local typ, IR = IR & 0xE0000, IR & 0x1FFF
    if typ == 0 then -- JMP
      CPU.PC = IR
    elseif typ == 0x2000 then -- JMPZ
      if CPU.D_STACK[CPU.T] == 0 then
        CPU.PC = IR
      end
      CPU.T = CPU.T + 1 % CONST.STACK_SIZE
    elseif typ == 0x4000 then -- CALL
      CPU.R = CPU.R + 1 % CONST.STACK_SIZE
      CPU.R_STACK[CPU.R] = CPU.PC + 1 % CONST.MEM_SIZE
      CPU.PC = IR
    elseif typ == 0x6000 then -- ALU
      ALU(IR)
    end
  end
end
