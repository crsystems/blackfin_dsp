/**************************************************************************
interruptA.S: Configure PF7 and PF6 to generate an interrupt when pushed.
The interrupt routine decides from which pin the interrupt came from and
therefore acts differently:

Button A (PF7) -> LED A turns on and off after 1s (2nd interrupt: core timer)
Button B (PF6) -> Writes the character 'x' to the temrinal

This assembler source needs a C preprocessor to remove C-style comments
and to handle include files and substitutions of makros and constants.

gcc option -xassembler-with-cpp is not needed for file extension .S:
bfin-elf-gcc -c -I ../inc interrupt.S

The bfkit boot loader will take care of stack and clock initialisation:
stack 4kB scratchpad ram, core clock 384.000MHz, system clock 96.000MHz

(C) 2007, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include <defBF532.h>           // includes also "def_LPBlackfin.h"

.data
.section    .rodata
titl:       .string "\r\nHello World!\r\n";
term:       .string "\r\nBye...\r\n";

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls

            CALL initx;
            P0.L = titl;
            P0.H = titl;
            CALL txstr;

            // Set PF sensitivity to "edge" for key A and B
            P0.H = HI(FIO_EDGE);    
            P0.L = LO(FIO_EDGE);
            R0.L = W[P0];
            BITSET(R0, 6);
            BITSET(R0, 7);
            W[P0] = R0.L;

            // Set PF Polarity to "falling edge" for key A and B
            P0.H = HI(FIO_POLAR);    
            P0.L = LO(FIO_POLAR);
            R0.L = W[P0];
            BITSET(R0, 6);
            BITSET(R0, 7);
            W[P0] = R0.L;

            // unmask Interrupt A for PF6 and PF7
            P0.L = LO(FIO_MASKA_D);
            P0.H = HI(FIO_MASKA_D);
            R0 = W[P0];
            BITSET(R0, 6);
            BITSET(R0, 7);
            W[P0] = R0;

            // write interrupt routine for interrupt A to Event Vector Table
            P0.L = LO(EVT12);       
            P0.H = HI(EVT12);
            P1.L = intchoose;
            P1.H = intchoose;
            [P0] = P1;

            // unmask Core Interrupt for interrupt A
            P0.L = LO(IMASK);
            P0.H = HI(IMASK);
            R0 = [P0];
            BITSET(R0, 12);
            [P0] = R0;

            // unmask System Interrupt for interrupt A
            P0.L = LO(SIC_IMASK);
            P0.H = HI(SIC_IMASK);
            R0 = [P0];
            BITSET(R0, 19);
            [P0] = R0;

            /* core timer inerrupt configuration */

            // unmask interrupt for core timer
            P0.H = HI(IMASK);
            P0.L = LO(IMASK);
            R0 = [P0];
            BITSET(R0, 6);
            [P0] = R0;

            // write intTmr to Event Vector Table
            P0.H = HI(EVT6);
            P0.L = LO(EVT6);
            P1.H = intTmr;
            P1.L = intTmr;
            [P0] = P1;

            /* Core timer configuration */
            
            // set scale paramter to 1
            P0.H = HI(TSCALE);
            P0.L = LO(TSCALE);
            R0 = 0 (Z);
            [P0] = R0;

// main loop
mloop:      
            CALL rxchr;
            IF !CC JUMP continue;
            R1 = 'q'(Z);          // 'q' --> quit
            CC = R0 == R1;
            IF CC JUMP mexit;

continue:   JUMP mloop;

intchoose: 
            [--SP] = ASTAT;
            [--SP] = RETS;
            [--SP] = (R7:7, P5:4);
            [--SP] = R0;

            // check PF6 and PF7
            P5.L = LO(FIO_FLAG_D);
            P5.H = HI(FIO_FLAG_D);
            R7 = W[P5];
            CC = BITTST(R7, 7);
            IF CC JUMP intA;
checkB:     CC = BITTST(R7, 6);
            IF CC JUMP intB;
intEnd:     R0 = [SP++];
            (R7:7, P5:4) = [SP++];
            RETS = [SP++];
            ASTAT = [SP++];
            RTI;

intA:       
            // clear PF7
            R7 = W[P5];
            BITCLR(R7, 7);
            BITCLR(R7, 5);        // turn LED A on
            W[P5] = R7;

            // set period to 1s
            P4.H = HI(TPERIOD);
            P4.L = LO(TPERIOD);
            R0.H = 0x16E3; 
            R0.L = 0x6000;
            [P4] = R0;

            // start core timer
            P4.H = HI(TCNTL);
            P4.L = LO(TCNTL);
            R0 = [P4];
            BITSET(R0, 0);        // Activate Timer
            BITSET(R0, 1);        // start timer
            [P4] = R0;

            JUMP checkB;

intB:        
            // clear PF6
            R7 = W[P5];
            BITCLR(R7, 6);
            W[P5] = R7;
            R0 = 'x' (X);
            CALL txchr;	          // send 'x' to terminal
            JUMP intEnd;

intTmr:     [--SP] = ASTAT;
            [--SP] = RETS;
            [--SP] = (R7:7, P5:5);

            P5.L = LO(FIO_FLAG_D);
            P5.H = HI(FIO_FLAG_D);

            R7.L = W[P5];
            BITSET(R7,5);         // turn LED A off
            W[P5] = R7.L;

            (R7:7, P5:5) = [SP++];
            RETS = [SP++];
            ASTAT = [SP++];
            RTI;

mexit:      P0.h = term;
            P0.l = term;
            CALL txstr;
            R0 = 27(z);
            CALL txchr;
            RETS = [SP++];
            RTS;
