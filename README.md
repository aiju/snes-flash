# SNES flash cartridge

This repository contains schematics/board layout, VHDL and assembly code for a SNES MicroSD flash cartridge.

## How to build

Use WLA-DX to build the ROM to give a rom.mif file which is copied to the vhdl directory.
Quartus compiles the vhdl and the rom.mif into a .sof file which can be flashed using JTAG.
To generate a file for flashing onto the onboard flash convert the .sof file to a .pof and then a .rpd file.
Finally reverse the bits in each byte in the .rpd file to yield snescart.bin.
Copy it onto the sd card and press L+R+Start+Select to flash the firmware. 

## SD card format

The filesystem on the card must be FAT32.
Folders and file names of any length are fine.
ROM file names must end in either .sfc or .smc. SMC headers are fine and Lorom/Hirom is autodetected.
Savegames need to created on a computer in the appropriate size (as deduced from the header in the file).
They need to have the same name as the ROM but have their name extension replaced by sav.

## Bugs

SD card hotswap occasionally causes trouble. Avoid.
Never touch the card while the game is running, removing the card during gameplay will disable saving until the next reset (to prevent corrupting another card).
Games larger than 32 megabits, using more than 64 kilobit of SRAM and using expansion chips are not supported (the SRAM limit is the easiest to fix).

## TODO

- Implement lockout chip (current board revision is flawed)
- Implement creating save files (or at least a PC tool for that purpose)
- Make the menus prettier

## Links

- [The schematics and board layout as PDF](http://aiju.de/snesflash.pdf)
