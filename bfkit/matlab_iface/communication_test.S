/**************************************************************************
matIntTemplate.S: Template for visualiziing numbers on the DSP in matlab.
Start in Matlab serial_plot.m and a sawtooth signal is visualized.
Use bflod without the terminal (without the -t option).

(C) 2014, ISI/ETH Zurich, cschuerc@isi.ee.ethz.ch
**************************************************************************/
#include    <defBF532.h>

.data

fir_coeff:	.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000
		.short	0x0000

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls

	    //UART BAUD 9600 INIT
            //enable mapping to UART_DLL & UART_DLH
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
		IF CC JUMP measure;

		R1 = 'f';
		CC = R0 == R1;
		IF CC JUMP fir;

		R1 = 'i';
		CC = R0 == R1;
		IF CC JUMP iir;

		R1 = 'F';
		CC = R0 == R1;
		IF CC JUMP update_fir;

		R1 = 'I';
		CC = R0 == R1;
		IF CC JUMP update_iir;

		JUMP main_loop;





measure:
	CALL measure_function;
	JUMP main_loop;
fir:
	CALL fir_function;
iir:
	CALL iir_function;
update_fir:
	CALL update_fir_function;
	JUMP main_loop;
update_iir: 
	CALL update_iir_function;
	JUMP main_loop;




measure_function:
	R0 = 'x';
	CALL txchr;
	R0 = '\n';
	CALL txchr;
	RTS;

fir_function:

iir_function:

update_fir_function:

update_iir_function:
