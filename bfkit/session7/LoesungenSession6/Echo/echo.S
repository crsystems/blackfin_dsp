/**************************************************************************
pass.S: audio passthrough example using codec.o

Compilation: bfin-elf-gcc -c -I ../include pass.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o pass.x pass.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
#define DBUFLEN 48000/2

.data
.section extram
.align 4;
dbuf: .space DBUFLEN*4;

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       R0 = 1 (Z);              // initialize codec using mic in
            CALL inicodec;
            // initialize circular buffer
            I0.H = dbuf;
            I0.L = dbuf;
            B0 = I0;
            L0.H = HI(4*DBUFLEN);
            L0.L = LO(4*DBUFLEN);

            // clear buffer
            P5.H = HI(DBUFLEN);
            P5.L = LO(DBUFLEN);
            R7 = 0 (Z);
            LOOP clearinpbuf LC0 = P5;
            LOOP_BEGIN clearinpbuf;
            [I0++] = R7;
            nop;
            LOOP_END clearinpbuf;

            R7.L = 0x2000;           // a = 1/4

mloop:      CALL rxsport;            // receive right channel --> R0.L
            R1 = R0;
            CALL rxsport;            // receive left channel --> R0.H
            R0 <<= 16;
            R0 = R1 | R0;
            [I0++] = R0;
            R1 = R0;
            R0 <<= 16;
            R1.L = 0x0000;
            A0 = R0;
            A1 = R1;

            R1 = [I0];               // get Sample u[k-K]

            R0.L = (A0 += R7.L * R1.L), R0.H = (A1 += R7.L * R1.H); // y[k] = u[k] + a * u[k-K]
            
            R1 = R0;
            CALL txsport;           // send right channel
            R0 = R1;
            R0 >>= 16;
            CALL txsport;           // send left channel

            JUMP mloop;             // loop forever
