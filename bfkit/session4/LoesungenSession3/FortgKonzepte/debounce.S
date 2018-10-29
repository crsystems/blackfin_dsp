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
dkeyahitcount: .int 0

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls

            P0.H = HI(FIO_FLAG_C);   // turn LED B on
            P0.L = LO(FIO_FLAG_C);
            R0.L = 0x0010;
            W[P0] = R0;
            SSYNC;

// main loop
mloop:      CALL keycka;             // key A hit?
            IF !CC JUMP keyb;        // no: check keyb
            CALL ledupd;             // yes: count keyhits with two LEDs

// check if key b is hit. If it is, return to boot loader.
keyb:       CALL keyckb;             // key B hit?
            IF !CC JUMP mloop;       // no: return to main loop
            RETS = [SP++];           // yes: restore callers address
            RTS;                     // and return to boot loader

// debounced key check, return with CC=1 if key a is pressed
keycka:     [--SP] = (R7:5, P5:4);   // save registers
            P5.H = HI(FIO_FLAG_D);   // read key input
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5](Z);
            CC = !BITTST(R7,7);
            P5.H = dkeya;            // get debounce variable
            P5.L = dkeya;
            P4.H = dkeyahitcount;    // get key hit counter  
            P4.L = dkeyahitcount;						 
            R7 = [P5];
            R5 = [P4];
            IF CC JUMP keyahit;      // jump if key pressed
            R7 = 0(Z);               // else dkeya = 0
            R5 = 0(Z);               // reset key hit counter
            JUMP keyaret;            // return with CC=0
            keyahit:
            R7 += 1;                 // increment count

// if R5 == 0 use KEYHIT, if R5 == 1 use KEYMAX, else use KEYRPT
            R6.H = HI(KEYHIT);       // use KEYHIT to compare
            R6.L = LO(KEYHIT);			 
            CC = R5 == 0;
            IF CC JUMP check;
            R6.H = HI(KEYRPT); 	     // use KEYRPT to compare      
            R6.L = LO(KEYRPT);
            CC = R5 == 1;
            IF !CC JUMP check;
            R6.H = HI(KEYMAX);       // use KEYMAX if R5 == 1    
            R6.L = LO(KEYMAX);

check:      CC = R6 <= R7;           // alias !CC = R7 < R6;
            IF !CC JUMP keyaret;     // no: return with CC=0
            CC = R7 == R6;
            R5 += 1;                 // increment key hit counter
            R7 = 0;                  // reset debounce variable
            keyaret:
            [P5] = R7;               // save debounce variable
            [P4] = R5;               // save key hit counter
            (R7:5, P5:4) = [SP++];   // restore registers
            RTS;

// simple key check, return with CC=1 if  key b is pressed
keyckb:     [--SP] = (R7:7, P5:5);   // save registers
            P5.H = HI(FIO_FLAG_D);   // read key input
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5] (Z);
            CC = !BITTST(R7,6);
            (R7:7, P5:5) = [SP++];   // restore registers
            RTS;

// change LEDs to next binary pattern
ledupd:     P0.H = HI(FIO_FLAG_D);
            P0.L = LO(FIO_FLAG_D);
            R0 = W[P0](Z);
            BITTGL(R0,4);
            CC = BITTST(R0,4);
            IF !CC JUMP ledupd0;
            BITTGL(R0,5);
            ledupd0:
            W[P0] = R0;
            RTS;
