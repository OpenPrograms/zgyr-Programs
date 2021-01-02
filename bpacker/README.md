# bpacker

A program for compressing and flashing files to EEPROM.


## Download

```
wget https://raw.githubusercontent.com/OpenPrograms/zgyr-Programs/master/installer.lua

installer && rm installer.lua
```


## Usage
```
bpacker [options] <filename>


Options:

  -q           quiet mode, don't ask questions
  
  -m           minify code before compressing (unsafe)
  
  -h, --help   display this help and exit
```


## TODO

- [ ] Make a more cleverly packer
- [ ] Add lz4 or lzss algorithm
- [ ] Improve the minifier