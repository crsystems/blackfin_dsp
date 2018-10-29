/****************************************************************************

cinit.S: A stripped version of bfinit.S

Omits initialization of stack, clocks and mode since this is already
done by the serial boot loader (sboot).
 
! Better use bfinit.S when you can afford the small memory overhead
! (about 256 Bytes), though some initialisation is done twice.

Link this ahead of other objects to jump to the main() routine
of C programmes. You can also start with inline assembly code
asm("P0.H = _main; P0.H = _main; JUMP(P0)"); or place the main()
routine ahead of all other procedures (but then prototypes must
be inserted before main for procedures called by main).

building bfinit.o:
bfin-elf-gcc -c -I ../include cinit.S

compiling user code (c or assembler):
bfin-elf-gcc -c -I ../include myprog.c

linking: (use linker script bfkit.ldf, cinit.o is the first object)
bfin-elf-ld -T bfkit.ldf -o myprog cinit.o myprog.o

(C) 2007, ISI/ETH Zurich, strebel@isi.ee.ethz.ch
****************************************************************************/

.text

// start is the entry point of the code executed after reset
.global start
start:

P0.H = _main;                   // address of main() in c program
P0.L = _main;
JUMP (P0);                      // jump to main() and return from there

