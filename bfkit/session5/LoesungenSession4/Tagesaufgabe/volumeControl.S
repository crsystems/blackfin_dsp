/**************************************************************************
volumeControl.S: software volume control example using codec.o

Compilation: bfin-elf-gcc -c -I ../include volumeControl.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o volumeControl.x volumeControl.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"

#define  KEYHIT   10000         // depends on mloop time

.data

dkeya:  .int 0           // .byte=8bit .short=16bit .int=32bit
dkeyb:  .int 0

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       R0 = 0 (Z);              // initialize codec using line in
            CALL inicodec;
            R1.L = 0x4000;           // sample weight for left channel
            R2.L = 0x4000;           // sample weight for right channel
            R3.L = 0x0800;           // sample weight step

mloop:      CALL keyckb;
            IF !CC JUMP keya;        // if key b is pressed change weight on both channels
            R1.L = R1.L + R3.L (S);  // saturate weight on left channel if needed
            R2.L = R2.L - R3.L;			
			CC = BITTST(R2, 15);	 // check if R2 is negative by loading it's sign bit into CC
			/*
			Alternative way to check if R2 is negative:
			R2 <<= 16;				 // By shifting R2.L to R2.H one can check if R2 is negative or not
			CC = R2 < 0;
			*/
            IF !CC JUMP nosatright;  // saturate weight on right channel if needed
            R2 = 0;
nosatright: //R2 >>= 16;

keya:       CALL keycka;
            IF !CC JUMP audio;       // if key a is pressed change weight on both channels
            R2.L = R2.L + R3.L (S);  // saturate weight on right channel if needed
            R1.L = R1.L - R3.L;
			CC = BITTST(R1, 15);	 // check if R1 is negative by loading it's sign bit into CC
			/*
			//Alternative way to check if R1 is negative:
			R1 <<= 16;
			CC = R1 < 0;
			*/
            IF !CC JUMP nosatleft;   // saturate weight on left channel if needed
            R1 = 0;
nosatleft:  //R1 >>= 16;

audio:      CALL rxsport;            // receive left channel
            R0 = R0.L * R1.L;		 // signed multiplication of 1.15 x 1.15 leads to a 1.31 result
            R0 >>>= 16;				 // thus R0 needs to be shifted down by 16 bits again
            CALL txsport;            // transmit left channel
            CALL rxsport;            // receive right channel
            R0 = R0.L * R2.L;
            R0 >>>= 16;
            CALL txsport;            // transmit right channel
            JUMP mloop;              // loop forever

// debounced key check, return with CC=1 if key a is pressed
keycka:     [--SP] = (R7:6, P5:5);   // save registers
            P5.H = HI(FIO_FLAG_D);   // read key input
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5](Z);
            CC = !BITTST(R7,7);
            P5.H = dkeya;            // get debounce variable
            P5.L = dkeya;
            R7 = [P5];
            IF CC JUMP keyahit;      // jump if key pressed
            R7 = 0(Z);               // else dkeya = 0
            JUMP keyaret;            // return with CC=0
keyahit:
            R7 += 1;                 // increment count
            R6.H = HI(KEYHIT);       // KEYHIT reached?
            R6.L = LO(KEYHIT);
            CC = R6 <= R7;           // alias !CC = R7 < R6;
            IF !CC JUMP keyaret;     // no: return with CC=0
            CC = R7 == R6;
            IF CC JUMP keyaret;      // yes: return with CC=1
            R7 = 0;                 // saturation at KEYHIT
keyaret:
            [P5] = R7;               // save debounce variable
            (R7:6, P5:5) = [SP++];   // restore registers
            RTS;

// debounced key check, return with CC=1 if key b is pressed
keyckb:     [--SP] = (R7:6, P5:5);   // save registers
            P5.H = HI(FIO_FLAG_D);   // read key input
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5](Z);
            CC = !BITTST(R7,6);
            P5.H = dkeyb;            // get debounce variable
            P5.L = dkeyb;
            R7 = [P5];
            IF CC JUMP keybhit;      // jump if key pressed
            R7 = 0(Z);               // else dkeya = 0
            JUMP keybret;            // return with CC=0
keybhit:
            R7 += 1;                 // increment count
            R6.H = HI(KEYHIT);       // KEYHIT reached?
            R6.L = LO(KEYHIT);
            CC = R6 <= R7;           // alias !CC = R7 < R6;
            IF !CC JUMP keybret;     // no: return with CC=0
            CC = R7 == R6;
            IF CC JUMP keybret;      // yes: return with CC=1
            R7 = 0;                 // saturation at KEYHIT
keybret:
            [P5] = R7;               // save debounce variable
            (R7:6, P5:5) = [SP++];   // restore registers
            RTS;
