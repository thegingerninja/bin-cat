bincat.out: bincat.o
	ld -o bincat bincat.o

bincat.o: bincat.asm
	nasm -f elf64 -l bincat.lst bincat.asm -o bincat.o

clean:
	rm bincat bincat.o bincat.lst
