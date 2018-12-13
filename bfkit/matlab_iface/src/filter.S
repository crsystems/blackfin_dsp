/**************************************************************************
matIntTemplate.S: Template for visualiziing numbers on the DSP in matlab.
Start in Matlab serial_plot.m and a sawtooth signal is visualized.
Use bflod without the terminal (without the -t option).

(C) 2014, ISI/ETH Zurich, cschuerc@isi.ee.ethz.ch
**************************************************************************/
#include    <defBF532.h>
#define		FIR_ORDER	21	// = order + 1 because we save the current sample in the circular buffers too
#define		IIR_ORDER	2	
.data

fir_coeff:	.short	0xfe19		// space for the FIR coefficients
		.short	0xfdf4
		.short  0xfdd2		// initially not filtering at all
		.short	0xfdb2		// fortunately, the coefficients are symmetrical
		.short	0xfd96		// which means, that we can use them in reverse without special care
		.short	0xfd7d
		.short	0xfd68
		.short  0xfd57
		.short	0xfd4b
		.short	0xfd44
		.short	0x3f16
		.short	0xfd44
		.short	0xfd4b
		.short	0xfd57		// TODO	delete the hardcoded filter after testing
		.short	0xfd68
		.short	0xfd7d
		.short	0xfd96
		.short	0xfdb2
		.short	0xfdd2
		.short	0xfdf4
		.short	0xfe19          // newest input sample (shoud be biased with 0.5 = 0x4000)

iir_coeff:	.short  0x0000		// b0
		.short  0x0000		// b1
		.short  0x0000		// b2 
		.short  0x0000		// a1
		.short  0x0000		// a2 
		.short	0x0000		// a0

.align 4
fir_buffer:	.space 4*FIR_ORDER;	// input buffer for the FIR filter (4 bytes a sample times 20 samples = 80 bytes)

iir_buffer:	.space 20;	// input buffer for the IIR filter (4 bytes a sample times 6 samples = 24 bytes)



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


// function, that loops and waits for user input, before any filtering was selected
//
//
main_loop:
		CALL rxchr;
		IF !CC JUMP main_loop;

		R2 = 'm';
		CC = R0 == R2;
		IF !CC JUMP fir;
		CALL measure_function;

fir:		R2 = 'f';
		CC = R0 == R2;
		IF !CC JUMP iir;
		R1 = 0 (Z);
		RETS = [SP++];
		JUMP filter_signal;		// branch to filter_signal, as this function becomes the new "main"

iir:		R2 = 'i';
		CC = R0 == R2;
		IF !CC JUMP update_fir;
		R1 = 1 (Z);
		RETS = [SP++];
		JUMP filter_signal;		// similar to execve('filter_signal')

update_fir:	R2 = 'F';
		CC = R0 == R2;
		IF !CC JUMP update_iir;
		CALL update_fir_function;

update_iir:	R2 = 'I';
		CC = R0 == R2;
		IF !CC JUMP endian;
		CALL update_iir_function;

endian:		R2 = 'e';
		CC = R0 == R2;
		IF !CC JUMP main_loop;
		CALL endianness_function;

		JUMP main_loop;



// function to initialize the circular buffers with zero
//
//
init_buffers:
		[--SP] = (R7:0, P5:0);
		[--SP] = RETS;

		I0.H = fir_buffer;		// Circular buffer 0 => FIR filter
		I0.L = fir_buffer;
		B0 = I0;
		L0.H = HI(4*FIR_ORDER);
		L0.L = LO(4*FIR_ORDER);
		
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
		L1.H = HI(20);
		L1.L = LO(20);

		P5 = 5;		
		LOOP cleariirbuf LC0 = P5;	// Clearing circular buffer for IIR
		LOOP_BEGIN cleariirbuf;
			[I1++] = R7;
			nop;
		LOOP_END cleariirbuf;

		RETS = [SP++];
		(R7:0, P5:0) = [SP++];
		RTS;



// function for measuring the filter response to samples sent via UART
//
//
measure_function:
		[--SP] = (R7:5, P5:4);
		[--SP] = RETS;
		CALL init_buffers;

measure_loop:	
		CALL rxchr;			// wait for data from MATLAB
		IF !CC JUMP measure_loop;

		R6 = R0;
		R7 = 'e';
		CC = R0 == R7;			// if the data equals 'e' this means the measurement is done
		IF !CC JUMP measure_filter;
		JUMP measure_exit;

measure_filter:					// otherwise it is simply the lower byte
		CALL rxchr;			// therefore we wait for the upper byte

		IF !CC JUMP measure_filter;

		CC = R0 == R7;
		IF CC JUMP measure_exit;
		
		R0 <<= 8;			// and construct the 16 bit word from that
		R0 = R0 | R6;

		R5 = R0;			// also, as the filters are awaiting a 32 bit (left and right channel) signal
		R5 <<= 16;			// we build a mono signal

		R0 = R0 | R5;

		R7 = 0 (Z);			// and decide which filter shall be used
		CC = R1 == R7;
		IF CC JUMP measure_fir;
		JUMP measure_iir;	
measure_fir:
		CALL apply_fir;
		JUMP measure_send_data;	

measure_iir:	
		CALL apply_iir;
		
measure_send_data:
		R0 >>= 16;			// we randomly choose the upper channel to be evaluated

		R6 = R0;
		R6 >>= 8;			// this is sent back in two (byte-) pieces

		CALL txdec;

		R0 = R6;

		CALL txdec;

		CALL txbr;

		JUMP measure_loop;		// and the loop begins again

measure_exit:
		RETS = [SP++];
		(R7:5, P5:4) = [SP++];
		RTS;	



// function, that acts as micro OS and filters the incoming signal with the specified filter
//
//
filter_signal:
		[--SP] = (R7:6, P5:4);
		[--SP] = R0;	
		[--SP] = RETS;

		CALL init_buffers;	// initialize the circular buffers

filter_loop:		
		CALL rxsport;	// recieve left channel
		R7 = R0;
		CALL rxsport;	// recieve right channel
		R0 <<= 16;
		R0 = R7 | R0;	// right channel = R7.H, left channel = R7.L


		R7 = 0;		

		CC = R1 == R7;	// deciding which filter should be used: == 0 => FIR, != 0 => IIR
		IF !CC JUMP call_iir; 	

call_fir:	CALL apply_fir; // apply FIR filter to R0
		JUMP send_filtered;

call_iir:	CALL apply_iir; // apply IIR filter to R0

send_filtered:	R7 = R0;	// get filtered sample from R0

		R7 >>= 16;	// R7.L = right channel, R7.H = 0
		R0 <<= 16;
		R0 >>= 16;	// R0.L = left channel, R0.H = 0

				
		CALL txsport;	// sending filtered sample
				//|
		R0 = R7;	//|
				//|
		CALL txsport;	//v

		CALL rxchr;		// data received via UART?
		IF !CC JUMP filter_loop;

		R2 = 'm';		// measure function desired
		CC = R0 == R2;
		IF !CC JUMP filter_fir;
		CALL measure_function;	

		CALL init_buffers;	// after measure returns, the circular buffers are cleared

		JUMP filter_loop;	// and jump to the loop again

filter_fir:	R2 = 'f';		// FIR filter operation desired
		CC = R0 == R2;
		IF !CC JUMP filter_iir;
		R1 = 0 (Z);
		JUMP filter_loop;		// just jump to the loop start, as we are supplying the desired function already
		CALL init_buffers;

filter_iir:	R2 = 'i';		// IIR filter operation desired
		CC = R0 == R2;
		IF !CC JUMP filter_update_fir;
		R1 = 1 (Z);
		CALL init_buffers;
		JUMP filter_loop;
	

filter_update_fir:	
		R2 = 'F';		// FIR parameter update desired
		CC = R0 == R2;
		IF !CC JUMP filter_update_iir;
		CALL update_fir_function;
		JUMP filter_loop;

filter_update_iir:	
		R2 = 'I';		// IIR parameter update desired
		CC = R0 == R2;
		IF !CC JUMP filter_endian;
		CALL update_iir_function;

filter_endian:	R2 = 'e';		// endianness test desired
		CC = R0 == R2;
		IF !CC JUMP filter_loop;
		CALL endianness_function;


		JUMP filter_loop;




// function for applying an IIR filter to a signal sample in R0
//
//
apply_iir:	[--SP] = (R7:5, P5:4);
		[--SP] = RETS;
	
		[I1] = R0;					// current input sample in first position of circular buffer

		P5.H = iir_coeff;				// P5 holds the address of the coefficients
		P5.L = iir_coeff;

		P4 = 3 (Z);				// first loop multiplies order + 1 input samples

		A0 = A1 = 0;					// clearing the accumulator registers

		R5 = 0 (Z);					// initializing the down shift value
		
		LOOP iir_calc_loop1 LC0 = P4;
		LOOP_BEGIN iir_calc_loop1;
			R7 = W[P5++] (X) || R6 = [I1];		// R7.L holds the current coefficient, R6 the appropriate sample
			A0 += R7.L * R6.L, A1 += R7.L * R6.H;	// A0 is responsible for the left channel, A1 for the right
			[I1++] = R5;				// the current value in the chain is replaced by the preceeding one
			R5 = R6;				// and the replacement for the next value is set to the current val.
		LOOP_END iir_calc_loop1;


		P4 = 2 (Z);				// second loop multiplies order times output samples

		R5 = 0 (Z);

		LOOP iir_calc_loop2 LC0 = P4;
		LOOP_BEGIN iir_calc_loop2;
			R7 = W[P5++] (X) || R6 = [I1];
			A0 += R7.L * R6.L, A1 += R7.L * R6.H;
			[I1++] = R5;
			R5 = R6;
		LOOP_END iir_calc_loop2;

		R7 = W[P5];

		R0.L = A0, R0.H = A1;
		
		A0 = R0.L * R7.L;

		A1 = R0.H * R7.L;

		R0.L = A0 (S2RND);
		R0.H = A1 (S2RND);

		//R7 = W[P5] (X);					// the last coefficient has to be a0 (scaling value for the output)

		//R7 <<= 1;					// WARNING: may be bullshit, but multiplying by to, to compensate
								// that the coefficients are saved as half their value

		//R0.L = R0.L * R7.L, R0.H = R0.H * R7.L;		// multiplying the final output by the scaling value


		P4 = I1;					// the circular buffer should now be in its initial position again
			
		R5 = I1;
	
		R5 += 12;

		I1 = R5;					// 3 values times 4 bytes makes 12 byte offset for y[k]

		[I1] = R0;					// saving the just calculated y[k] in the circular buffer

		I1 = P4;					// and restoring the circular buffer

		RETS = [SP++];
		(R7:5, P5:4) = [SP++];
		RTS;



// function for applying an FIR filter to a signal sample in R0
//
//
apply_fir:	[--SP] = (R7:6, P5:4);		// awaiting left and right channel sample in R0

		[I0++] = R0;	// store combined values in circular buffer

		P5.H = fir_coeff;
		P5.L = fir_coeff;

		P4.H = HI(FIR_ORDER);
		P4.L = LO(FIR_ORDER);

		A0 = A1 = 0;	// clearing accumulator registers
	
		LOOP fir_calc_loop LC0 = P4;
		LOOP_BEGIN fir_calc_loop;
			R7 = W[P5++] (X) || R6 = [I0++];	// R6 = (order-i)'th filter parameter, R7 = (order-i)'th sample
			A0 += R6.L * R7.L, A1 += R6.H * R7.L;	// A0 is responsible for the left channel, A1 for the right
		LOOP_END fir_calc_loop;

		R0.L = A0 (S2RND);
		R0.H = A1 (S2RND);		// Saving A0 and A1 to R0 and multiplying by 2
						// Thereby returning the filtered sample in R0
		

		(R7:6, P5:4) = [SP++];
		RTS;



//function, that updates the fir coefficients with newer values
//
//
update_fir_function:
		[--SP] = RETS;
		[--SP] = (R7:5, P5:4);
		[--SP] = R0;

		R7 = 0;

		P5.H = HI(FIR_ORDER);
		P5.L = LO(FIR_ORDER);		

		R6 = P5;

		P4.H = fir_coeff;
		P4.L = fir_coeff;

		
update_fir_loop:
		CC = R7 < R6;
		IF !CC JUMP update_fir_exit;

		CALL rxchr;
		IF !CC JUMP update_fir_loop;		

		R5 = R0
		
update_fir_wait_second_byte:
		
		CALL rxchr;
		IF !CC JUMP update_fir_wait_second_byte;

		R0 <<= 8;

		R5 = R5 | R0;

		W[P4++] = R5;
		
		R7 += 1;

		JUMP update_fir_loop;

update_fir_exit:
		R0 = [SP++];
		(R7:5, P5:4) = [SP++];
		RETS = [SP++];	
		RTS;




// function, that updates the iir coefficients with newer values
//
//
update_iir_function:	
		[--SP] = RETS;
		[--SP] = (R7:5, P5:4);
		[--SP] = R0;

		R7 = 0;

		R6 = 6 (Z);

		P4.H = iir_coeff;
		P4.L = iir_coeff;
		
update_iir_loop:
		CC = R7 < R6;
		IF !CC JUMP update_iir_exit;

		CALL rxchr;
		IF !CC JUMP update_iir_loop;		

		R5 = R0;
		
update_iir_wait_second_byte:
		
		CALL rxchr;
		IF !CC JUMP update_iir_wait_second_byte;

		R0 <<= 8;

		R5 = R5 | R0;

		W[P4++] = R5;
		
		R7 += 1;

		JUMP update_iir_loop;

update_iir_exit:
		R0 = [SP++];
		(R7:5, P5:4) = [SP++];
		RETS = [SP++];
		RTS;



// function for testing the endianness of the UART data transmission
//
//
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
		CALL txchr;

		CALL txbr;

		JUMP endian_exit;

little_endian:	
		CC = BITTST(R5, 8);		// If something went funky, this ensures, that the 9'th bit of the word is set
		IF !CC JUMP big_endian;		// so it really is little endian

		R0 = 'l';
		CALL txchr;

		CALL txbr;

endian_exit:
		RETS = [SP++];
		(R7:0, P5:0) = [SP++];
		RTS;

