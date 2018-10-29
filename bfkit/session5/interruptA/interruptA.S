/**************************************************************************
interruptA.S: Configure PF7 to generate an interrupt when pushed

This assembler source needs a C preprocessor to remove C-style comments
and to handle include files and substitutions of makros and constants.

gcc option -xassembler-with-cpp is not needed for file extension .S:
bfin-elf-gcc -c -I ../inc interrupt.S

The bfkit boot loader will take care of stack and clock initialisation:
stack 4kB scratchpad ram, core clock 384.000MHz, system clock 96.000MHz

(C) 2007, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include <defBF532.h>           // includes also "def_LPBlackfin.h"

#define  KEYHIT   50000         // depends on mloop time
#define  KEYMAX   2000000
#define  KEYRPT   500000

.data
.section    .rodata
titl:       .string "\r\nHello World!\r\n";
term:       .string "\r\nbyebye ...\r\n";


dkeya:  .int 0           // .byte=8bit .short=16bit .int=32bit

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls

            CALL initx;
            P0.L = titl;
            P0.H = titl;
            CALL txstr;

            // Set PF sensitivity to "edge"
            P0.H = HI(FIO_EDGE);    
            P0.L = LO(FIO_EDGE);
            R0.L = W[P0];
            BITSET(R0, 7);
            W[P0] = R0.L;

            // Set PF Polarity to "falling edge"
            P0.H = HI(FIO_POLAR);    
            P0.L = LO(FIO_POLAR);
            R0.L = W[P0];
            BITSET(R0, 7);
            W[P0] = R0.L;

            // unmask Interrupt A for PF7
            P0.L = LO(FIO_MASKA_D);
            P0.H = HI(FIO_MASKA_D);
            R0 = W[P0];
            BITSET(R0, 7);
            W[P0] = R0;

            // write interrupt routine for interrupt A to Event Vector Table
            P0.L = LO(EVT12);       
            P0.H = HI(EVT12);
            P1.L = intA;
            P1.H = intA;
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

// main loop
mloop:      
            CALL rxchr;
            IF !CC JUMP continue;
            R1 = 'q'(Z);                // 'q' --> quit
            CC = R0 == R1;
            IF CC JUMP mexit;

continue:   JUMP mloop;

intA:       [--SP] = ASTAT;
            [--SP] = RETS;
            [--SP] = (R7:7, P5:5);
            [--SP] = R0;
            
            // clear PF7
            P5.L = LO(FIO_FLAG_D);
            P5.H = HI(FIO_FLAG_D);
            R7 = W[P5];
            BITCLR(R7, 7);
            W[P5] = R7;

            R0 = 'o' (X);
            CALL txchr;

            R0 = [SP++];
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
