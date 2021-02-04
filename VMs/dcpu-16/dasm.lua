local registers = {
  A = 0, B = 1, C = 2,
  X = 3, Y = 4, Z = 5,
  I = 6, J = 7,
  PEEK = 25,
  PICK = 26,
  SP = 27,
  PC = 28,
  EX = 29,
}

local codes = {
  SET = 1, MDI = 9,  IFC = 17, ADX = 26,
  ADD = 2, AND = 10, IFE = 18, SBX = 27,
  SUB = 3, BOR = 11, IFN = 19, STI = 30,
  MUL = 4, XOR = 12, IFG = 20, STD = 31,
  MLI = 5, SHR = 13, IFA = 21,
  DIV = 6, ASR = 14, IFL = 22,
  DVI = 7, SHL = 15, IFU = 23,
  MOD = 8, IFB = 16,
}

local scodes = {
  JSR = 1, INT = 8, IAG = 9, IAS = 10,
  RFI = 11, IAQ = 12, HWN = 16, HWQ = 17, HWI = 18
}

local function assemble(str)
  str = str:gsub(';[%g ]+\n','\n'):gsub(',',' '):gsub(' +',' ')
  
end