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
0000 0000 0000 0000 JMP
0010 0000 0000 0000 JMPZ
0100 0000 0000 0000 CALL
0110 0000 0000 0000 ALU
1000 0000 0000 0000 LIT
--]]

local char, tonumber = string.char, tonumber
local args = {...}
if #args ~= 1 then
  print('Usage: assembler <file.j1>')
  return
else
  filename = args[1]
end

local opcodes = {
  ['D--']    = 0x0001,
  ['D++']    = 0x0002,
  ['R--']    = 0x0004,
  ['R++']    = 0x0008,
  ['N->[T]'] = 0x0010,
  ['T->R']   = 0x0020,
  ['T->N']   = 0x0040,
  ['R->PC']  = 0x0080,
  ['JMP']    = 0x0000,
  ['JMPZ']   = 0x2000,
  ['CALL']   = 0x4000,
  ['ALU']    = 0x6000,
  ['LIT']    = 0x8000,
}

local alu = {
  [0] = 'T', 'N', 'T+N', 'T&N',
  'T|N', 'T^N', '~T', 'N==T',
  'N<T', 'N>>T', 'T-1', 'R',
  '[T]', 'N<<T', 'DSP', 'Nu<T'
}

for i = 0, #alu do
  opcodes[alu[i]] = i << 9
end

local definitions = {}

local program = ''

local f = io.open(filename)
local data = f:read('*a')
f:close()

for line in data:gmatch('[^\n]+') do
  local result = 0
  local counter = 0
  local def = false
  local name = nil
  for code in line:gmatch('[^%s]+') do
    counter = counter + 1
    if code == '%define' and counter == 1 then
      def = true
    elseif def and counter == 2 then
      name = code
    else
      if opcodes[code:upper()] then
        result = result | opcodes[code:upper()]
      elseif tonumber(code) then
        result = result | tonumber(code)
      elseif code == '//' then
        break
      elseif definitions[code] then
        result = definitions[code]
        break
      else
        print('UNKNOWN WORD: ' .. code)
      end
    end
  end
  if type(result) ~= 'string' then
    result = char((result & 0xFF00) >> 8) .. char(result & 0x00FF)
  end
  if def then
    definitions[name] = result
  else
    if type(result) == 'string' then
      program = program .. result
    end
  end
end

f = io.open(filename .. '.ac', 'w')
f:write(program)
f:close()
