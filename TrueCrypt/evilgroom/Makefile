CFLAGS=-Wall -Wextra -m32 -g
LDFLAGS=-m32
CC=gcc

evilgroom: evilgroom.o logger.o
	$(CC) $(LDFLAGS) -o evilgroom evilgroom.o logger.o

logger.o: logger.asm
	nasm -f elf logger.asm

emul:
	make evilgroom; cp bak.devsda devsda ; ./evilgroom devsda ; qemu-system-i386 devsda; gunzip tc_bl_patched.gz; ./evilgroom devsda

clean:
	rm -f logger.o evilgroom.o

mrproper: clean
	rm -f evilgroom
