--[[
0000 0000 0000 0001 d-1    
0000 0000 0000 0010 d+1    
0000 0000 0000 0100 r-1    
0000 0000 0000 1000 r+1    
0000 0000 0001 0000 N->[T]
0000 0000 0010 0000 T->R  
0000 0000 0100 0000 T->N
0000 0000 1000 0000 R->PC
0000 0000 0000 0000 T
0000 0001 0000 0000 N
0000 0010 0000 0000 T+N
0000 0011 0000 0000 T&N
0000 0100 0000 0000 T|N
0000 0101 0000 0000 T^N
0000 0110 0000 0000 ~T
0000 0111 0000 0000 N==T
0000 1000 0000 0000 N<T
0000 1001 0000 0000 N>>T
0000 1010 0000 0000 T-1
0000 1011 0000 0000 R
0000 1100 0000 0000 [T]
0000 1101 0000 0000 N<<T
0000 1110 0000 0000 DSP
0000 1111 0000 0000 Nu<T
--]]

local string = string
local args = {...}
if #args ~= 1 then
  print('Usage: assembler <program>')
  return
else
  filename = args[1]
end

local opcodes = {
  ['d-1'] = 1,
  ['d+1'] = 2,
  ['r-1'] = 4,
  ['r+1'] = 8,
  ['N->[T]'] = 16,
  ['T->R'] = 32,
  ['T->N'] = 64,
  ['R->PC'] = 128
}

local alu = {
  [0] = 'T', 'N', 'T+N', 'T&N',
  'T|N', 'T^N', '~T', 'N==T',
  'N<T', 'N>>T', 'T-1', 'R',
  '[T]', 'N<<T', 'DSP', 'Nu<T'
}

for i = 1, #alu do
  opcodes[alu[i]] = i << 9
end

local program = ''

local f = io.open(filename)
local data = f:read('*a')
f:close()

for line in data:gmatch('[^\n]+') do
  local result = 0
  for code in line:gmatch('[^%s]+') do
    if opcodes[code] then
      result = result | opcodes[code]
    end
  end
  program = program .. string.char(result & 0xff00) .. string.char(result & 0x00ff)
end

local f = io.open(filename .. '.j1', 'w')
f:write(program)
f:close()
