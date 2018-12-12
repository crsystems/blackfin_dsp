/**************************************************************************
fir.S: Implementation of two FIR Filters
If Button A is pressed activate lowpass filter
If Button B is pressed activate highpass filter
If no Button is pressed, pass unfiltered audio data

Compilation: bfin-elf-gcc -c -I ../include fir.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o fir.x fir.o codec.o uart.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#define input_iir 3
#define output_iir 2

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
.data
// filter coefficients are found using fdatool in matlab
// convert fractions to 1.15(hex) in matlab : hex(fi(Num, 1, 16, 15))
// lowpass, IIR, Butterforth, Fc=2kHz, order=2
bcoeff: 	.short 0x3074	//coefficients for the Output   
            	.short 0x9f18   
            	.short 0x3074   
acoeff:         .short 0x1bd1   //coefficients for the Input
            	.short 0xb98a   
            	.short 0x3074   

.align 4
inputbuf:   	.space 4*input_iir;
outputbuf:	.space 4*output_iir;

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

	    [I0++] = R0;

            CALL lowiir;

	    R1 = R0;
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

            // initialize circular buffer for input
            I0.H = inputbuf;
            I0.L = inputbuf;
            B0 = I0;
            L0.H = HI(4*input_iir);
            L0.L = LO(4*input_iir);

	    // init circular buffer for output
	    I1.H = outputbuf;
            I1.L = outputbuf;
            B1 = I1;
            L1.H = HI(4*output_iir);
            L1.L = LO(4*output_iir);


            // clear buffer
            P5 = input_iir;
            R7 = 0 (Z);
            LOOP clearinpbuf LC0 = P5;
            LOOP_BEGIN clearinpbuf;
            [I0++] = R7;
	    [I1++] = R7;
            nop;
            LOOP_END clearinpbuf;

	    [I1--] = R7;

            (R7:0, P5:0) = [SP++];
            RETS = [SP++];
            RTS;

lowiir:     LINK 0;
            [--SP] = (R7:4, P5:3);


	    P5.H = acoeff;          // Output IIR coefficients
            P5.L = acoeff;
            
	    P4.H = bcoeff;          // Input IIR coefficients
            P4.L = bcoeff;

            R7 = W[P4++] (X);
	    R6 = W[P5++] (X);

            P3 = input_iir;
            LOOP lowfirstep1 LC0 = P3;
            LOOP_BEGIN lowfirstep1;
                R7 = W[P4++] (X) || R5 = [I0++];
                A0 += R5.L * R7.L, A1 += R5.H * R7.L;
            LOOP_END lowfirstep1;
            
            P3 = output_iir;
            LOOP lowfirstep2 LC1 = P3;
            LOOP_BEGIN lowfirstep2;
                R7 = W[P5++] (X) || R5 = [I1++];
                A0 += R5.L * R7.L, A1 += R5.H * R7.L;
            LOOP_END lowfirstep2;
            
            R0.L = A0 (S2RND); 
	    R0.H = A1 (S2RND);
	    R7 = W[P5] (X);
	    R0.L = R0.L * R7.L, R0.H = R0.H * R7.L;

	    [I1++] = R0;

            (R7:4, P5:3) = [SP++];
            UNLINK;
            RTS;

// close console and get back to bootloader
mexit:      R0 = 27 (X);
            CALL txchr;
            RETS = [SP++];
            RTS;
