/**************************************************************************
matIntTemplate.S: Template for visualiziing numbers on the DSP in matlab.
Start in Matlab serial_plot.m and a sawtooth signal is visualized.
Use bflod without the terminal (without the -t option).

(C) 2014, ISI/ETH Zurich, cschuerc@isi.ee.ethz.ch
**************************************************************************/
#include    <defBF532.h>
#define		FIR_ORDER	21
#define		IIR_ORDER	2	
.data

fir_coeff:	.short	0x0000		// space for the FIR coefficients
		.short	0x0000		// initially not filtering at all
		.short	0x0000		// fortunately, the coefficients are symmetrical
		.short	0x0000		// which means, that we can use them in reverse without special care
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
		.short  0x0000
		.short	0x0001

iir_coeff:	.short  0x0000		// space for the IIR coefficients
		.short  0x0000		// initially not filtering at all
		.short  0x0000		//TODO	document in which order the coefficients have to be supplied
		.short  0x0000
		.short  0x0000
		.short	0x0000

last_filter:	.byte	0x00		// to remember which filter was previously selected before a measurement or a coefficient
					// update
					// 0 => FIR, 1 => IIR

.align 4
fir_buffer:	.space 4*FIR_ORDER;	// input buffer for the FIR filter (4 bytes a sample times 20 samples = 80 bytes)

iir_buffer:	.space 4*IIR_ORDER;	// input buffer for the IIR filter (4 bytes a sample times 6 samples = 24 bytes)



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
		IF !CC JUMP endian;
		CALL update_iir_function;

endian:		R1 = 'e';
		CC = R0 == R1;
		IF !CC JUMP main_loop;
		CALL endianness_function;

		JUMP main_loop;


/*

Clearing the memory for the circular buffers of the FIR and IIR filters

*/


init_buffers:
		[--SP] = (R7:0, P5:0);
		[--SP] = RETS;

		I0.H = fir_buffer;		// Circular buffer 0 => FIR filter
		I0.L = fir_buffer;
		B0 = I0;
		L0.H = HI(4*FIR_ORDER);
		L0.L = LO(4*IIR_ORDER);
		
		P5 = FIR_ORDER;
		R7 = 0;

		LOOP clearfirbuf LC0 = P5;	// Clearing circular buffer for FIR
		LOOP_BEGIN clearfirbuf;
		[I0++] = R7;
		nop;
		LOOP_END clearfirbuf;


		I1.H = iir_buffer;		// Circular buffer 1 => IIR buffer
		I1.L = iir_buffer;
		B1 = I1;
		L1.H = HI(4*IIR_ORDER);
		L1.L = LO(4*IIR_ORDER);

		P5 = IIR_ORDER;		
		LOOP cleariirbuf LC0 = P5;	// Clearing circular buffer for IIR
		LOOP_BEGIN cleariirbuf;
		[I1++] = R7;
		nop;
		LOOP_END cleariirbuf;

		RETS = [SP++];
		(R7:0, P5:0) = [SP++];
		RTS;






measure_function:

	

fir_function:
		[--SP] = (R7:6, P5:4);
		[--SP] = R0;	
		[--SP] = RETS;

		CALL init_buffers;	// initialize the circular buffers

		P5.H = last_filter;
		P5.L = last_filter;
		R7 = 0;
		B[P5] = R7;		// writing last_filter variable for measure function
fir_loop:		
		CALL rxsport;	// recieve left channel
		R7 = R0;
		CALL rxsport;	// recieve right channel
		R0 <<= 16;
		R7 = R7 | R0;	// right channel = R7.H, left channel = R7.L

		[I0++] = R7;	// store combined values in circular buffer

		P5.H = fir_coeff;
		P5.L = fir_coeff;

		P4 = FIR_ORDER;

		A0 = A1 = 0;	// clearing accumulator registers
	
		LOOP fir_calc_loop LC0 = P4;
		LOOP_BEGIN fir_calc_loop;
			R6 = W[P5++] (X) || R7 = [I0++];	// R6 = (order-i)'th filter parameter, R7 = (order-i)'th sample
			A0 += R7.L * R6.L, A1 += R7.H * R6.L;	// A0 is responsible for the left channel, A1 for the right
		LOOP_END fir_calc_loop;

		R0.L = A0 (S2RND);
		R0.H = A1 (S2RND);		// Saving A0 and A1 to R0 and multiplying by 2

		R7 = R0;
		R7 >>= 16;	// R7.L = right channel, R7.H = 0
		R0 <<= 16;
		R0 >>= 16;	// R0.L = left channel, R0.H = 0

				
		CALL txsport;	// sending filtered sample
				//|
		R0 = R7;	//|
				//|
		CALL txsport;	//v


		CALL rxchr;		// data received via UART?
		IF !CC JUMP fir_loop;

		R1 = 'm';		// measure function desired
		CC = R0 == R1;
		IF !CC JUMP fir_fir;
		CALL measure_function;	

		CALL init_buffers;	// after measure returns, the circular buffers are cleared

		JUMP fir_loop;		// and jump to the loop again

fir_fir:	R1 = 'f';		// FIR filter operation desired
		CC = R0 == R1;
		IF !CC JUMP fir_iir;
		JUMP fir_loop;		// just jump to the loop start, as we are supplying the desired function already

fir_iir:	R1 = 'i';		// IIR filter operation desired
		CC = R0 == R1;
		IF !CC JUMP fir_update_fir;
		
		RETS = [SP++];		// restore return address and registers from stack
		R0 = [SP++];		
		(R7:6, P5:4) = [SP++];
		JUMP iir_function;	// and branch to the fir function
					// that way it seems to the fir functio, as it were called from the main loop
					// and we do not waste stack space with nesting unnecessary function calls

fir_update_fir:	R1 = 'F';		// FIR parameter update desired
		CC = R0 == R1;
		IF !CC JUMP fir_update_iir;
		CALL update_fir_function;
		JUMP fir_loop;

fir_update_iir:	R1 = 'I';		// IIR parameter update desired
		CC = R0 == R1;
		IF !CC JUMP fir_loop;
		CALL update_iir_function;

		JUMP fir_loop;




iir_function:	//TODO

update_fir_function:
		[--SP] = RETS;
		[--SP] = (R7:5, P5:4);
		[--SP] = R0;

		R7 = 0;

		P5.H = HI(FIR_ORDER);
		P5.L = LO(FIR_ORDER);

		R6.L = W[P5];

		P4.H = fir_coeff;
		P4.L = fir_coeff;

		
update_fir_loop:
		CC = R7 < R6;
		IF !CC JUMP update_fir_exit;

		CALL rxchr;
		IF !CC JUMP update_fir_loop;		

		R5 = R0			//TODO find out endianness reliably of matlab word transfer
		
update_fir_wait_second_byte:
		
		CALL rxchr;
		IF !CC JUMP update_fir_wait_second_byte;

		R0 <<= 8;

		R5 = R5 | R0;			// currently using little endian

		W[P4++] = R5;
		
		R7 += 1;

		JUMP update_fir_loop;

update_fir_exit:
		R0 = [SP++];
		(R7:5, P5:4) = [SP++];
		RETS = [SP++];	



update_iir_function:	
		[--SP] = RETS;
		[--SP] = (R7:5, P5:4);
		[--SP] = R0;

		R7 = 0;

		P5.H = HI(IIR_ORDER);
		P5.L = LO(IIR_ORDER);

		R6.L = W[P5];

		P4.H = iir_coeff;
		P4.L = iir_coeff;

		
update_iir_loop:
		CC = R7 < R6;
		IF !CC JUMP update_iir_exit;

		CALL rxchr;
		IF !CC JUMP update_iir_loop;		

		R5 = R0			//TODO find out endianness of matlab word transfer
		
update_iir_wait_second_byte:
		
		CALL rxchr;
		IF !CC JUMP update_iir_wait_second_byte;

		R0 <<= 8;

		R5 = R5 | R0;			// currently using little endian

		W[P4++] = R5;
		
		R7 += 1;

		JUMP update_iir_loop;

update_iir_exit:
		R0 = [SP++];
		(R7:5, P5:4) = [SP++];
		RETS = [SP++];



endianness_function:	
		[--SP] = (R7:0, P5:0);
		[--SP] = RETS;
		R7 = 0(Z);
		R6 = 0(Z);

endian_loop1:	CALL rxchr;			// Receive first byte of word to be tested
		IF !CC JUMP endian_loop1;
		R7 = R0;			// Store it in R7
endian_loop2:	CALL rxchr;			// Receive second byte
		IF !CC JUMP endian_loop2;	
		R6 = R0;			// Store it in R6

		R6 <<= 8;			// Shift second byte up 8 bits (implying little endian)
		R5 = R7 | R6;			// Combine both bytes


		R5 += 1;			// Add 1 to ensure bittests fail when wrong endianness

		CC = BITTST(R5, 0);		// If that +1 set the lsb, we have little endian
		IF CC JUMP little_endian;
		
big_endian:	R0 = 'b';			// If not (eg. lowes byte is now 00000010), we have big endian
		//R0 = R7;
		CALL txchr;

		R0 = '\n';
		CALL txchr;

		JUMP endian_exit;

little_endian:	
		CC = BITTST(R5, 8);		// If something went funky, this ensures, that the 9'th bit of the word is set
		IF !CC JUMP big_endian;		// so it really is little endian

		R0 = 'l';
		CALL txchr;

		R0 = '\n';
		CALL txchr;

endian_exit:
		RETS = [SP++];
		(R7:0, P5:0) = [SP++];
		RTS;

