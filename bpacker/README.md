# bpacker

A program for compressing and flashing files to EEPROM.


## Requirements

* Data Card any tier

* Internet Card required for installation


## Download

```
oppm install bpacker
```


## Usage
```
bpacker [options] <filename>


Options:

  -q           quiet mode, don't ask questions
  
  -m           minify code before compressing (unsafe)
  
  -l, --lzss   use lzss algorithm for compression (no data card required)
  
  -h, --help   display this help and exit
```


## TODO

- [ ] Make a more cleverly packer
- [x] Add lz4 or lzss algorithm
- [ ] Improve the minifier