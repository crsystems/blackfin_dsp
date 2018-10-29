
mystery.o:     file format elf32-bfin

Disassembly of section .text:

00000000 <_mystery>:
   0:	00 e8 04 00 	LINK 0x10;		/* (16) */
   4:	b8 b0       	[FP + 0x8] = R0;
   6:	b8 a0       	R0 = [FP + 0x8];
   8:	08 0c       	CC = R0 == 0x1;
   a:	04 10       	IF !CC JUMP 0x12 <_mystery+0x12>;
   c:	b8 a0       	R0 = [FP + 0x8];
   e:	f0 bb       	[FP -0x4] = R0;
  10:	0a 20       	JUMP.S 0x24 <_mystery+0x24>;
  12:	b8 a0       	R0 = [FP + 0x8];
  14:	f8 67       	R0 += -0x1;		/* ( -1) */
  16:	ff e3 f5 ff 	CALL 0x0 <_mystery>;
  1a:	08 30       	R1 = R0;
  1c:	b8 a0       	R0 = [FP + 0x8];
  1e:	11 30       	R2 = R1;
  20:	c2 40       	R2 *= R0;
  22:	f2 bb       	[FP -0x4] = R2;
  24:	f0 b9       	R0 = [FP -0x4];
  26:	01 e8 00 00 	UNLINK;
  2a:	10 00       	RTS;
