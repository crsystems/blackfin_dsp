/**************************************************************************
debounce.S: use keys to increment/decrement a binary code on two LEDs.

This assembler source needs a C preprocessor to remove C-style comments
and to handle include files and substitutions of makros and constants.

gcc option -xassembler-with-cpp is not needed for file extension .S:
bfin-elf-gcc -c -I ../inc debounce.S

The bfkit boot loader will take care of stack and clock initialisation:
stack 4kB scratchpad ram, core clock 384.000MHz, system clock 96.000MHz

(C) 2007, ISI/ETH Zurich, strebel@isi.ee.ethz.ch
**************************************************************************/

#include <defBF532.h>           // includes also "def_LPBlackfin.h"

#define  KEYHIT   50000         // depends on mloop time
#define  KEYMAX   2000000
#define  KEYRPT   500000

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            P0.H = HI(FIO_FLAG_C);
            P0.L = LO(FIO_FLAG_C);
            R0.L = 0x0010;
            W[P0] = R0;              // turn LED B on
            SSYNC;

	    R2.L = 0xFFFF;
	    R2.H = 0x00FF;


            mloop:                   // Main Loop
            
	    R4 = 0(Z);

	    wait_loop:
	    
	    R4 += 0x1;
	    CC = R4 < R2;
	    IF CC JUMP wait_loop;

	    CALL ledAdd1;

	    CALL keycka;
	    
	    IF !CC JUMP mloop;


	    R2 >>>= 1;

	    JUMP mloop;
 
            RETS = [SP++];           // yes: restore callers address
            RTS;                     // and return to boot loader

keycka:
	    [--SP] = (R7:3, P5:4);
            R6.H = HI(KEYMAX);
            R6.L = LO(KEYMAX);       // R6 = KEYHIT
	    R4 = 0(Z);

            P4.H = HI(FIO_FLAG_D);
            P4.L = LO(FIO_FLAG_D);
            R5 = W[P4](Z);
            
	    c_loop:
	    
	    CC = !BITTST(R5,7);      // CC = Is key A pressed?
            IF !CC JUMP l_exit;      // if key A pressed: jump

	    R4 += 0x1;
	    


	    R7 = 0(Z);
	    R3 = 0xD(Z);

	    w_loop1:
	    R7 += 0x1;

	    CC = R3 <= R7;
	    IF !CC JUMP w_loop1;



	    CC = R6 <= R4;
	    IF CC JUMP l_exit;
	    JUMP c_loop;

	    l_exit:
            (R7:3, P5:4) = [SP++];
            RTS;

// change LEDs to next binary pattern (add 1)
ledAdd1:    [--SP] = (R7:7, P5:5);
            P5.H = HI(FIO_FLAG_D);
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5](Z);
            BITTGL(R7,4);            // Toggle LSB
            CC = BITTST(R7,4);
            IF !CC JUMP ledupd;
            BITTGL(R7,5);            // Toggle MSB

            ledupd:
            W[P5] = R7;              // Update LEDs
            (R7:7, P5:5) = [SP++];
            RTS;
