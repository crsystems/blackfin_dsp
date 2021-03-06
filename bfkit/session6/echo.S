/**************************************************************************
echo.S: audio echo example using codec.o

Compilation: bfin-elf-gcc -c -I ../include pass.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o pass.x pass.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
#define	DBUFLEN  24000

.data
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


		R7.L = 0x4000;		//1/4 as a factor		

mloop:      CALL rxsport;            // receive right channel
		R1 = R0;
		R1<<=16;

            CALL rxsport;            // receive left channel

		R2 = [I0];	     // restore u[k-K] to R3 and R4
		R3 = R2.L (Z);	     //left channel
		R4 = R2;
		R4>>=16;	     //right channel
	
		R6 = R0;
		R6<<=16;
		A0 = R6;		// left channel
		A1 = R1;		// right channel
		
		R6 = 0x0(Z);
	
		R5.L = ( A0 += R7.L * R3.L );
		R6.H = ( A1 += R7.L * R4.L );
		R6>>=16;

		R1 = R1|R0;		//save left and right channel combined to
		[I0++] = R1;		//circular buffer
		

		R0 = R6;
            CALL txsport;            // transmit right channel
		R0 = R5;
            CALL txsport;            // transmit left channel
            JUMP mloop;              // loop forever
