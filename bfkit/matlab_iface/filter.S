/**************************************************************************
matIntTemplate.S: Template for visualiziing numbers on the DSP in matlab.
Start in Matlab serial_plot.m and a sawtooth signal is visualized.
Use bflod without the terminal (without the -t option).

(C) 2014, ISI/ETH Zurich, cschuerc@isi.ee.ethz.ch
**************************************************************************/
#include    <defBF532.h>

.data

fir_coeff:	.short	0x0000		// space for the FIR coefficients
		.short	0x0000		// initially not filtering at all
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0001

iir_coeff:	.short  0x0000		// space for the IIR coefficients
		.short  0x0000		// initially not filtering at all
		.short  0x0000
		.short  0x0000
		.short  0x0000

last_filter:	.byte	0x00		// to remember which filter was previously selected before a measurement or a coefficient
					// update

.align 4
fir_buffer:	.space 80;		// input buffer for the FIR filter (4 bytes a sample times 20 samples = 80 bytes)

iir_buffer:	.space 20;		// input buffer for the IIR filter (4 bytes a sample times 5 samples = 20 bytes)



.text

init:       [--SP] = RETS;           // push RETS to allow nested calls

	    //UART BAUD 9600 INIT
            //enable mapping to UART_DLL  UART_DLH
            P0.H = HI(UART_LCR);
            P0.L = LO(UART_LCR);
            R0 = [P0];
            BITSET(R0,7);
            [P0] = R0;

            //set divisor
            P0.H = HI(UART_DLL);
            P0.L = LO(UART_DLL);
            R0 = 0x71;
            [P0] = R0;

            P0.H = HI(UART_DLH);
            P0.L = LO(UART_DLH);
            R0 = 0x02;
            [P0] = R0;

            //restore normal mapping to UART_THR
            P0.H = HI(UART_LCR);
            P0.L = LO(UART_LCR);
            R0 = [P0];
            BITCLR(R0,7);
            [P0] = R0;

            CALL initexec;          // use our own exception routine
            R0 = 0 (Z);             // initialize codec with line-in as input
            CALL inicodec;           
            CALL initx;             // initialize uart


/**************************************************************************
Exchange the code below by your own code. Note that you can not send data
to matlab at a too high speed.
**************************************************************************/
main_loop:
		CALL rxchr;
		IF !CC JUMP main_loop;

		R1 = 'm';
		CC = R0 == R1;
		IF !CC JUMP fir;
		CALL measure_function;

fir:		R1 = 'f';
		CC = R0 == R1;
		IF !CC JUMP iir;
		CALL fir_function;

iir:		R1 = 'i';
		CC = R0 == R1;
		IF !CC JUMP update_fir;
		CALL iir_function;

update_fir:	R1 = 'F';
		CC = R0 == R1;
		IF !CC JUMP update_iir;
		CALL update_fir_function;

update_iir:	R1 = 'I';
		CC = R0 == R1;
		IF !CC JUMP main_loop;
		CALL update_iir_function;

		JUMP main_loop;





measure_function:

fir_function:

iir_function:

update_fir_function:

update_iir_function:
