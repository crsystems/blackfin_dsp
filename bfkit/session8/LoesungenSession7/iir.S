/**************************************************************************
fir.S: Implementation of two FIR Filters
If Button A is pressed activate lowpass filter
If Button B is pressed activate highpass filter
If no Button is pressed, pass unfiltered audio data

Compilation: bfin-elf-gcc -c -I ../include fir.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o fir.x fir.o codec.o uart.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#define FIRN 2

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
.data
// filter coefficients are found using fdatool in matlab
// convert fractions to 1.15(hex) in matlab : hex(fi(SOS*0.5, 1, 16, 15)), hex(fi(G, 1, 16, 15))
// lowpass, IIR, Butterworth, Fs=48kHz, Fc=2000, order=2
lowb:
	.short 0x4000 // b_01
	.short 0x7fff // b_11
	.short 0x4000 // b_21
lowa:
	.short 0x4000 // a_01
	.short 0x977d // a_11
	.short 0x2c33 // a_21
lowG:
	.short 0x01d8 // g_1
	.short 0x7fff // g_2
// highpass, IIR, Butterworth, Fs=48kHz, Fc=2000, order=2
highb:
	.short 0x4000
	.short 0x8000
	.short 0x4000
higha:
	.short 0x4000
	.short 0xec51
	.short 0x0c0e
highG:
	.short 0x2fdf
	.short 0x7fff


.align 4
input:   .space 4*FIRN;
output:   .space 4*FIRN;

.text

init:       [--SP] = RETS;          // push RETS to allow nested calls
            JUMP main;              // jump to main program

main:       CALL initexec;          // use our own exception routine
            R0 = 0 (Z);             // initialize codec with line-in as input
            CALL inicodec;           
            CALL initx;             // initialize uart
            CALL initiir;           // initialize FIR buffers

mloop:      
            CALL rxsport;            // receive left channel --> R0.L
            R1 = R0;
            CALL rxsport;            // receive right channel --> R0.H
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

continue:   JUMP mloop;              // loop forever

initiir:    [--SP] = RETS;
            [--SP] = (R7:0, P5:0);

            // initialize circular buffer
            I0.H = input;
            I0.L = input;
            B0 = I0;
            L0.H = HI(4*FIRN);
            L0.L = LO(4*FIRN);

            // initialize circular buffer
            I1.H = output;
            I1.L = output;
            B1 = I1;
            L1.H = HI(4*FIRN);
            L1.L = LO(4*FIRN);

            // clear buffer
            P5 = FIRN;
            R7 = 0 (Z);
            LOOP clearinpbuf LC0 = P5;
            LOOP_BEGIN clearinpbuf;
            [I0++] = R7;
            [I1++] = R7;
            nop;
            LOOP_END clearinpbuf;

            (R7:0, P5:0) = [SP++];
            RETS = [SP++];
            RTS;

lowfirstep: LINK 0;
            [--SP] = (R7:4, P5:2);

            P5.H = lowb;          // IIR b coefficients
            P5.L = lowb;

            P4.H = lowa;          // IIR a coefficients
            P4.L = lowa; 

            P3.H = lowG;
            P3.L = lowG; 

            R7 = W[P3++] (X);
            R0.L = R0.L * R7.L, R0.H = R0.H * R7.L; // gain on input

            R7 = W[P5++] (X);
            P4 += 2; // skip first coefficient
            
            A0 = R7.L * R0.L, A1 = R7.L * R0.H;

            P2 = FIRN;
            LOOP lowfirstep1 LC0 = P2;
            LOOP_BEGIN lowfirstep1;
                R7 = W[P5++] (X) || R6 = [I0++];
                R5 = W[P4++] (X) || R4 = [I1++];
                A0 += R6.L * R7.L, A1 += R6.H * R7.L;
                A0 -= R4.L * R5.L, A1 -= R4.H * R5.L;
            LOOP_END lowfirstep1;
          
            I0 += 4;
            I1 += 4;
            [I0] = R0;
            R0.L = A0 (S2RND);
            R0.H = A1 (S2RND);
            R7 = W[P3] (X);
            R0.L = R0.L * R7.L, R0.H = R0.H * R7.L;
            [I1] = R0;
            (R7:4, P5:2) = [SP++];
            UNLINK;
            RTS;

higfirstep: LINK 0;
            [--SP] = (R7:4, P5:2);

            P5.H = highb;          // IIR b coefficients
            P5.L = highb;

            P4.H = higha;          // IIR a coefficients
            P4.L = higha; 

            P3.H = highG;
            P3.L = highG; 

            R7 = W[P3++] (X);
            R0.L = R0.L * R7.L, R0.H = R0.H * R7.L; // gain on input

            R7 = W[P5++] (X);
            P4 += 2; // skip first coefficient
            
            A0 = R7.L * R0.L, A1 = R7.L * R0.H;

            P2 = FIRN;
            LOOP highfirstep1 LC0 = P2;
            LOOP_BEGIN highfirstep1;
                R7 = W[P5++] (X) || R6 = [I0++];
                R5 = W[P4++] (X) || R4 = [I1++];
                A0 += R6.L * R7.L, A1 += R6.H * R7.L;
                A0 -= R4.L * R5.L, A1 -= R4.H * R5.L;
            LOOP_END highfirstep1;
          
            I0 += 4;
            I1 += 4;
            [I0] = R0;
            R0.L = A0 (S2RND);
            R0.H = A1 (S2RND);
            R7 = W[P3] (X);
            R0.L = R0.L * R7.L, R0.H = R0.H * R7.L;
            [I1] = R0;
            (R7:4, P5:2) = [SP++];
            UNLINK;
            RTS;

// close console and get back to bootloader
mexit:      R0 = 27 (X);
            CALL txchr;
            RETS = [SP++];
            RTS;
