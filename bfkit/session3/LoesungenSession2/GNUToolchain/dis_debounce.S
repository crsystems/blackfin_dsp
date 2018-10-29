
debounce.o:     file format elf32-bfin

Disassembly of section .text:

00000000 <init>:
   0:	67 01       	[--SP] = RETS;
   2:	48 e1 c0 ff 	P0.H = 0xffc0;		/* (-64)	P0=0xffc00000(-4194304) */
   6:	08 e1 04 07 	P0.L = 0x704;		/* (1796)	P0=0xffc00704(-4192508) */
   a:	00 e1 10 00 	R0.L = 0x10;		/* ( 16)	R0=0x10( 16) */
   e:	00 97       	W[P0] = R0;
  10:	24 00       	SSYNC;

00000012 <mloop>:
  12:	00 e3 0a 00 	CALL 0x26 <keycka>;
  16:	03 10       	IF !CC JUMP 0x1c <keyb>;
  18:	00 e3 2b 00 	CALL 0x6e <ledAdd1>;

0000001c <keyb>:
  1c:	00 e3 20 00 	CALL 0x5c <keyckb>;
  20:	f9 13       	IF !CC JUMP 0x12 <mloop>;
  22:	27 01       	RETS = [SP++];
  24:	10 00       	RTS;

00000026 <keycka>:
  26:	ec 05       	[--SP] = (R7:5, P5:4);
  28:	46 e1 00 00 	R6.H = 0x0;		/* (  0)	R6=0x0 <init>(  0) */
  2c:	06 e1 50 c3 	R6.L = 0xc350;		/* (-15536)	R6=0xc350(50000) */
  30:	4d e1 00 00 	P5.H = 0x0;		/* (  0)	P5=0x0 <init> */
  34:	0d e1 00 00 	P5.L = 0x0;		/* (  0)	P5=0x0 <init> */
  38:	4c e1 c0 ff 	P4.H = 0xffc0;		/* (-64)	P4=0xffc00000(-4194304) */
  3c:	0c e1 00 07 	P4.L = 0x700;		/* (1792)	P4=0xffc00700(-4192512) */
  40:	25 95       	R5 = W[P4] (Z);
  42:	3d 48       	CC = !BITTST (R5, 0x7);		/* bit  7 */
  44:	04 18       	IF CC JUMP 0x4c <keyahit>;
  46:	87 e1 00 00 	R7 = 0x0 (Z);		/*		R7=0x0 <init>(  0) */
  4a:	05 20       	JUMP.S 0x54 <writedkeya>;

0000004c <keyahit>:
  4c:	2f 91       	R7 = [P5];
  4e:	37 09       	CC = R7 <= R6;
  50:	02 10       	IF !CC JUMP 0x54 <writedkeya>;
  52:	0f 64       	R7 += 0x1;		/* (  1) */

00000054 <writedkeya>:
  54:	2f 93       	[P5] = R7;
  56:	3e 08       	CC = R6 == R7;
  58:	ac 05       	(R7:5, P5:4) = [SP++];
  5a:	10 00       	RTS;

0000005c <keyckb>:
  5c:	fd 05       	[--SP] = (R7:7, P5:5);
  5e:	4d e1 c0 ff 	P5.H = 0xffc0;		/* (-64)	P5=0xffc00000(-4194304) */
  62:	0d e1 00 07 	P5.L = 0x700;		/* (1792)	P5=0xffc00700(-4192512) */
  66:	2f 95       	R7 = W[P5] (Z);
  68:	37 48       	CC = !BITTST (R7, 0x6);		/* bit  6 */
  6a:	bd 05       	(R7:7, P5:5) = [SP++];
  6c:	10 00       	RTS;

0000006e <ledAdd1>:
  6e:	fd 05       	[--SP] = (R7:7, P5:5);
  70:	4d e1 c0 ff 	P5.H = 0xffc0;		/* (-64)	P5=0xffc00700(-4192512) */
  74:	0d e1 00 07 	P5.L = 0x700;		/* (1792)	P5=0xffc00700(-4192512) */
  78:	2f 95       	R7 = W[P5] (Z);
  7a:	27 4b       	BITTGL (R7, 0x4);		/* bit  4 */
  7c:	27 49       	CC = BITTST (R7, 0x4);		/* bit  4 */
  7e:	02 10       	IF !CC JUMP 0x82 <ledupd>;
  80:	2f 4b       	BITTGL (R7, 0x5);		/* bit  5 */

00000082 <ledupd>:
  82:	2f 97       	W[P5] = R7;
  84:	bd 05       	(R7:7, P5:5) = [SP++];
  86:	10 00       	RTS;
