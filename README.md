Binary Cat
==========

NASM x64 Assembly program to echo out a file as ones and zeros.
Yeap.. completely useless.  This was written just to learn
NASM and Intel Assembly Language.

Build
=====

    $ make

nasm -f elf64 -l bincat.lst bincat.asm -o bincat.o

ld -o bincat bincat.o

Run
===

    $ ./bincat testfile.txt 

0011000000110001001100100011001100110100001101010011011000110111001110000011100100001010
