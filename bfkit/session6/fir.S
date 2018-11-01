/**************************************************************************
echo.S: audio echo example using codec.o

Compilation: bfin-elf-gcc -c -I ../include pass.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o pass.x pass.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
#define	DBUFLEN  12

.data

firparam:	.short 0x0000;
		.short 0x026c;
		.short 0x08cf;
		.short 0x10bf;
		.short 0x1731;
		.short 0x19a9;
		.short 0x1731;
		.short 0x10bf;
		.short 0x08cf;
		.short 0x026c;
		.short 0x0000;	


.section extram
.align 4;
dbuf:	.space DBUFLEN*4;

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       R0 = 1 (Z);              // initialize codec using mic in
            CALL inicodec;

		//init circular buffer
		I0.L = dbuf;
		I0.H = dbuf;
		B0 = I0;
		L0.H = HI(DBUFLEN);
		L0.L = LO(DBUFLEN);

mloop:      CALL rxsport;            // receive right channel
		R0<<=16;
		R1 = R0;
            CALL rxsport;            // receive left channel
		R1 = R1 | R0;
		[I0++] = R1;
	
		CALL filter;
		R0 = R1;
            CALL txsport;            // transmit right channel
		R0 = R1;
		R0>>=16;
            CALL txsport;            // transmit left channel
            JUMP mloop;              // loop forever



filter:
		[--SP] = RETS;
		P0.L = firparam;
		P0.H = firparam;
		
		A0 = 0;
		A1 = 0;
		
		R0 = 0;

floop:		R1 = [I0];
		R2 = [I0++];

		R1<<=16;	//shift left channel up
		R1>>=16;	//and down
		R2>>=16;	//shift right channel down

		R3 = [P0++];
		R0 += 1;

		A0 += R3.L * R1.L;
		A1 += R3.L * R2.L;


		R5 = 11;
		CC = R0 < R5;
		IF CC JUMP floop;

		R4 = 0;

		R1.L = (A0 += R4.L * R4.L);
		R1.H = (A1 += R4.L * R4.L);

		RETS = [SP++];
		RTS;
		

		

