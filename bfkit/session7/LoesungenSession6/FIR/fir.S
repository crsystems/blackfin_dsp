/**************************************************************************
fir.S: Implementation of two FIR Filters
If Button A is pressed activate lowpass filter Fc=1kHz
If Button B is pressed activate lowpass filter Fc=500Hz
If no Button is pressed, pass unfiltered audio data

Compilation: bfin-elf-gcc -c -I ../include fir.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o fir.x fir.o codec.o uart.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#define FIRN 10

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
.data
// filter coefficients are found using fdatool in matlab
// convert fractions to 1.15(hex) in matlab : hex(fi(Num, 1, 16, 15))
// lowpass, FIR, Window, Fc=1kHz, order=10

lowfircoef:   .short 0x0ab9   
              .short 0x0b42   
              .short 0x0bb0   
              .short 0x0c01   
              .short 0x0c32   
              .short 0x0c43   
              .short 0x0c32   
              .short 0x0c01   
              .short 0x0bb0   
              .short 0x0b42   
              .short 0x0ab9

// filter coefficients are found using fdatool in matlab
// convert fractions to 1.15(hex) in matlab : hex(fi(Num, 1, 16, 15))
// lowpass, FIR, Window, Fc=500Hz, order=10
lowfircoef2:  .short 0x0000
              .short 0x026c
              .short 0x08cf
              .short 0x10bf
              .short 0x1731
              .short 0x19a9
              .short 0x1731
              .short 0x10bf
              .short 0x08cf
              .short 0x026c
              .short 0x0000

.align 4
inputbuf:   .space 4*FIRN;

.text

init:       [--SP] = RETS;          // push RETS to allow nested calls
            JUMP main;              // jump to main program

main:       CALL initexec;          // use our own exception routine
            R0 = 0 (Z);             // initialize codec with line-in as input
            CALL inicodec;           
            CALL initx;             // initialize uart
            CALL initfir;           // initialize FIR buffers

mloop:      
            CALL rxsport;           // receive left channel --> R0.L
            R1 = R0;
            CALL rxsport;           // receive right channel --> R0.H
            R0 <<= 16;
            R0 = R1 | R0;

            P5.H = HI(FIO_FLAG_D);
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5] (Z);
            CC = !BITTST(R7,7);     // button A --> lowpass
            IF !CC JUMP nobtnA;
            CALL lowfirstep;
nobtnA:     CC = !BITTST(R7,6);     // button B --> highpass
            IF !CC JUMP nobtnB;
            CALL higfirstep;

nobtnB:     R1 = R0;
            CALL txsport;           // send left channel
            R0 = R1;
            R0 >>= 16;
            CALL txsport;           // send right channel
            
            CALL rxchr;             // check if 'q' is pressed, exit if yes
            IF !CC JUMP continue;
            R1 = 'q' (Z);
            CC = R1 == R0;
            IF CC JUMP mexit;

continue:   JUMP mloop;             // loop forever

initfir:    [--SP] = RETS;
            [--SP] = (R7:0, P5:0);

            // initialize circular buffer
            I0.H = inputbuf;
            I0.L = inputbuf;
            B0 = I0;
            L0.H = HI(4*FIRN);
            L0.L = LO(4*FIRN);

            // clear buffer
            P5 = FIRN;
            R7 = 0 (Z);
            LOOP clearinpbuf LC0 = P5;
            LOOP_BEGIN clearinpbuf;
            [I0++] = R7;
            nop;
            LOOP_END clearinpbuf;

            (R7:0, P5:0) = [SP++];
            RETS = [SP++];
            RTS;

upinbuf:    LINK 0;
            [--SP] = (R7:0, P5:0);

            [I0] = R0;

            (R7:0, P5:0) = [SP++];
            UNLINK;
            RTS;

lowfirstep: LINK 0;
            [--SP] = (R7:6, P5:4);

            P5.H = lowfircoef;      // FIR coefficients
            P5.L = lowfircoef;

            R7 = W[P5++] (X);
            A0 = R7.L * R0.L, A1 = R7.L * R0.H;

            P4 = FIRN;
            LOOP lowfirstep1 LC0 = P4;
            LOOP_BEGIN lowfirstep1;
                R7 = W[P5++] (X) || R6 = [I0++];
                A0 += R6.L * R7.L, A1 += R6.H * R7.L;
            LOOP_END lowfirstep1;
            
            I0 -= 4;
            [I0] = R0;
            R0.L = A0, R0.H = A1;

            (R7:6, P5:4) = [SP++];
            UNLINK;
            RTS;

higfirstep: LINK 0;
            [--SP] = (R7:6, P5:4);

            P5.H = lowfircoef2;     // FIR coefficients
            P5.L = lowfircoef2;

            R7 = W[P5++] (X);
            A0 = R7.L * R0.L, A1 = R7.L * R0.H;

            P4 = FIRN;
            LOOP highfirstep1 LC0 = P4;
            LOOP_BEGIN highfirstep1;
                R7 = W[P5++] (X) || R6 = [I0++];
                A0 += R6.L * R7.L, A1 += R6.H * R7.L;
            LOOP_END highfirstep1;
            
            I0 -= 4;
            [I0] = R0;
            R0.L = A0, R0.H = A1;

            (R7:6, P5:4) = [SP++];
            UNLINK;
            RTS;

// close console and get back to bootloader
mexit:      R0 = 27 (X);
            CALL txchr;
            RETS = [SP++];
            RTS;
