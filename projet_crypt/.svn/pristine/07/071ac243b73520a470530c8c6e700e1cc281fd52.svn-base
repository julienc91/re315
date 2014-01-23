patch_tc: patch_tc.o logger.o
	gcc -m32 -o patch_tc patch_tc.o logger.o

patch_tc.o: patch_tc.c
	gcc -m32 -c patch_tc.c

logger.o: logger.asm
	nasm -f elf logger.asm


clean:
	rm -f logger.o patch_tc.o
