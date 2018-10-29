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

.data

dkeya:  .int 0           // .byte=8bit .short=16bit .int=32bit
.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            P0.H = HI(FIO_FLAG_C);
            P0.L = LO(FIO_FLAG_C);
            R0.L = 0x0010;
            W[P0] = R0;              // turn LED B on
            SSYNC;

            mloop:                   // Main Loop
            CALL keycka;             // key A hit?
            IF !CC JUMP keyb;        // no: check keyb
	    CALL ledAdd1;            // yes: count keyhits with two LEDs
	    CALL hold;
	    IF !CC JUMP keyb;

	    rloop:
	    CALL ledAdd1;
	    CALL repeat;
	    IF !CC JUMP keyb;
	    JUMP rloop;

            keyb:
            CALL keyckb;             // key B hit?
            IF !CC JUMP mloop;       // no: return to main loop
            RETS = [SP++];           // yes: restore callers address
            RTS;                     // and return to boot loader

// debounced key check, return with CC=1 if key A is pressed
keycka:     [--SP] = (R7:5, P5:4);
            R6.H = HI(KEYHIT);
            R6.L = LO(KEYHIT);       // R6 = KEYHIT
            P5.H = dkeya;            
            P5.L = dkeya;            // P5 = Pointer to dkeya

            P4.H = HI(FIO_FLAG_D);
            P4.L = LO(FIO_FLAG_D);
            R5 = W[P4](Z);
            CC = !BITTST(R5,7);      // CC = Is key A pressed?
            
            IF CC JUMP keyahit;      // if key A pressed: jump
            R7 = 0(Z);               // else:
            JUMP writedkeya;         //       dkeya = 0

            keyahit:
            R7 = [P5];               // Read dkeya
            CC = R7 <= R6;           // !CC = dkeya > KEYHIT
            IF !CC JUMP writedkeya;  // Saturation at (KEYHIT + 1)
            R7 += 1;                 // increment dkeya

            writedkeya:
            [P5] = R7;               // R7 -> dkeya
            CC = R6 == R7;           // CC = KEYHIT == dkeya
            (R7:5, P5:4) = [SP++];
            RTS;

hold:
	    [--SP] = (R7:3, P5:4);
            R6.H = HI(KEYMAX);
            R6.L = LO(KEYMAX);       // R6 = KEYHIT
	    R4 = 0(Z);

            P4.H = HI(FIO_FLAG_D);
            P4.L = LO(FIO_FLAG_D);
            R5 = W[P4](Z);
            
	    c_loop:
	    
	    CC = !BITTST(R5,7);      // CC = Is key A pressed?
            IF !CC JUMP loop_exit;      // if key A pressed: jump

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

repeat:
	    [--SP] = (R7:3, P5:4);
            R6.H = HI(KEYRPT);
            R6.L = LO(KEYRPT);       // R6 = KEYHIT
	    R4 = 0(Z);

            P4.H = HI(FIO_FLAG_D);
            P4.L = LO(FIO_FLAG_D);
            R5 = W[P4](Z);
            
	    check_loop:
	    
	    CC = !BITTST(R5,7);      // CC = Is key A pressed?
            IF !CC JUMP loop_exit;      // if key A pressed: jump

	    
	    R7 = 0(Z);
	    R3 = 0xD(Z);

	    w_loop2:
	    R7 += 0x1;

	    CC = R3 <= R7;
	    IF !CC JUMP w_loop2;
	    

	    R4 += 0x1;
	    CC = R6 <= R4;
	    IF CC JUMP loop_exit;
	    JUMP check_loop;

	    loop_exit:
            (R7:3, P5:4) = [SP++];
            RTS;


// simple key check, return with CC=1 if key B is pressed
keyckb:     [--SP] = (R7:7, P5:5);
            P5.H = HI(FIO_FLAG_D);   
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5] (Z);
            CC = !BITTST(R7,6);      // CC = Is key B pressed?
            (R7:7, P5:5) = [SP++];
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
