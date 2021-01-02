local fs = require('filesystem')
if not fs.exists('/usr/bin') then fs.makeDirectory('/usr/bin') end
if not fs.exists('/usr/lib') then fs.makeDirectory('/usr/lib') end
os.execute('wget -f https://raw.githubusercontent.com/BrightYC/Other/master/lzss.lua /usr/lib/lzss.lua')
os.execute('wget -f https://raw.githubusercontent.com/OpenPrograms/zgyr-Programs/bpacker/master/bpacker.lua /usr/bin/bpacker.lua')
os.execute('wget -f https://raw.githubusercontent.com/stravant/lua-minify/master/minify.lua /usr/bin/minify.lua')