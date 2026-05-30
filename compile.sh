nasm -f elf32 threads.asm -o threads.o
ld -m elf_i386 -o threads threads.o
./threads