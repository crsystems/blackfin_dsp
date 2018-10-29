/**************************************************************************
ledcounter.S: Increment/decrement a binary code on two LEDs. Use keys to change speed.

This assembler source needs a C preprocessor to remove C-style comments
and to handle include files and substitutions of makros and constants.

gcc option -xassembler-with-cpp is not needed for file extension .S:
bfin-elf-gcc -c -I ../inc ledcounter.S

The bfkit boot loader will take care of stack and clock initialisation:
stack 4kB scratchpad ram, core clock 384.000MHz, system clock 96.000MHz

(C) 2007, ISI/ETH Zurich, strebel@isi.ee.ethz.ch
**************************************************************************/

#include <defBF532.h>           // includes also "def_LPBlackfin.h"

#define  KEYHIT   50000         // depends on mloop time
#define  MINSPEED   2000000
#define  MAXSPEED   250000
#define  STEP   125000

.data

dkeya:  .int 0           // .byte=8bit .short=16bit .int=32bit
dkeyb:  .int 0
dspeed: .int 1000000

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls

            P0.H = HI(FIO_FLAG_C);   // turn LED B on
            P0.L = LO(FIO_FLAG_C);
            R0.L = 0x0010;
            W[P0] = R0;

            P5.H = dspeed;            
            P5.L = dspeed;

            R0 = [P5];               // set initial speed 1000000

            SSYNC;

// main loop
mloop:      CALL keycka;             // check if key A is pressed            
            IF CC JUMP decreaseSpeed;// if pressed decrease speed       
next1:      CALL keyckb;             // check if key B is pressed
            IF CC JUMP increaseSpeed;// if pressed increase speed
next2:      R0 += -1;
            CC = R0 <= 0;
            IF !CC JUMP mloop;
            P5.H = dspeed;            
            P5.L = dspeed;
            R0 = [P5];               // get current speed
            CALL ledupd;             
            JUMP mloop;

decreaseSpeed:
            [--SP] = (R7:5, P5:5);
            P5.H = dspeed;            
            P5.L = dspeed;
            R7 = [P5];               // get current speed
            R6.H = HI(STEP);         // step value 
            R6.L = LO(STEP);      
            R5.H = HI(MINSPEED);     // MINSPEED value
            R5.L = LO(MINSPEED);
            R7 = R7 + R6;
            CC = R7 <= R5;
            IF !CC JUMP nochange1;   // speed doesn't change if R7 > MINSPEED
            [P5] = R7;               // set new speed
nochange1: (R7:5, P5:5) = [SP++];
            JUMP next1;

increaseSpeed:
            [--SP] = (R7:5, P5:5);
            P5.H = dspeed;            
            P5.L = dspeed;
            R7 = [P5];               // get current speed
            R6.H = HI(STEP);         // step value 
            R6.L = LO(STEP);      
            R5.H = HI(MAXSPEED);     // MAXSPEED value
            R5.L = LO(MAXSPEED);
            R7 = R7 - R6;
            CC = R7 <= R5;
            IF CC JUMP nochange2;    // speed doesn't change if R7 < MAXSPEED
            [P5] = R7;               // set new speed
nochange2:  (R7:5, P5:5) = [SP++];
            JUMP next2;

// debounced key check for button A, return with CC=1 if key a is pressed
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
            R7 = R6;                 // saturation at KEYHIT
            keyaret:
            [P5] = R7;               // save debounce variable
            (R7:6, P5:5) = [SP++];   // restore registers
            RTS;

// debounced key check for button B, return with CC=1 if  key b is pressed
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
            R7 = R6;                 // saturation at KEYHIT
            keybret:
            [P5] = R7;               // save debounce variable
            (R7:6, P5:5) = [SP++];   // restore registers
            RTS;

// change LEDs to next binary pattern
ledupd:     [--SP] = (R7:7, P5:5);   // save registers
            P5.H = HI(FIO_FLAG_D);
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5](Z);
            BITTGL(R7,4);
            CC = BITTST(R7,4);
            IF !CC JUMP ledupd0;
            BITTGL(R7,5);
            ledupd0:
            W[P5] = R7;
            (R7:7, P5:5) = [SP++];   // restore registers
            RTS;
