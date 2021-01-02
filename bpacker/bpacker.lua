local component = require('component')
local fs = require('filesystem')
local shell = require('shell')
local eeprom = component.eeprom

local function usage()
  print('Usage: compress [options] <filename>' .. [[
  
Options:
  -q           quiet mode, don't ask questions
  -m           minify code before compressing (unsafe)
  -h, --help   display this help and exit]])
end

local args, options = shell.parse(...)
options.h = options.h or options.help
if #args == 0 or options.h then
  usage()
  return 1
end

local function flash(str)
  if not options.q then
    print('Flashing EEPROM ' ..  eeprom.address)
    print('Please do NOT power down or restart your computer during this operation!')
  end
  eeprom.set(str)
  if not options.q then
    print('All done! You can remove the EEPROM and re-insert the previous one now.')
  end
end

local function deflate(str)
  if not component.isAvailable('data') then
    io.stderr:write('This program requires an data card to run.\n')
    return
  end
  local decoder = "c=component l,i=c.list,c.invoke load(i(l('data',true)(),'inflate',i(l'eep'(),'get'):sub(107,-5)))() --[==["
  local data = component.data
  local result, reason = data.deflate(str)
  if not result then
    io.stderr:write(reason)
    return
  end
  result = decoder .. result .. ']==]'
  if #result < 4096 then
    flash(result)
  else
    io.stderr:write('This file cannot compress to 4KiB\n')
  end
end

local filename = shell.resolve(args[1])
local file_parentpath = fs.path(filename)

if fs.exists(file_parentpath) and not fs.isDirectory(file_parentpath) then
  io.stderr:write(string.format('Not a directory: %s\n', file_parentpath))
  return
end

if fs.isDirectory(filename) then
  io.stderr:write('File is a directory\n')
  return
end

if options.m then
  os.execute('minify.lua minify ' .. filename .. ' >> ' .. filename .. '.min')
  filename = filename .. '.min'
end

local f = io.open(filename)
deflate(f:read('*a'))
f:close()