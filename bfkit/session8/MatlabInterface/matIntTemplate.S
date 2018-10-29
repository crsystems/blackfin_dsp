/**************************************************************************
matIntTemplate.S: Template for visualiziing numbers on the DSP in matlab.
Start in Matlab serial_plot.m and a sawtooth signal is visualized.
Use bflod without the terminal (without the -t option).

(C) 2014, ISI/ETH Zurich, cschuerc@isi.ee.ethz.ch
**************************************************************************/
#include    <defBF532.h>

.data

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
            // Init registers for generating saw tooth
            R0 = 0;
            R1 = 10;


// main loop
sawtoothgen:P0.H = 0x0100;
            P0.L = 0x0000;
            LC0 = P0;
            LOOP delay1 LC0;        
            LOOP_BEGIN delay1;
            NOP;
            LOOP_END delay1;

	    CALL txdec;
	    CALL txbr;
            R0 += 1;
            CC = R0 <= R1;
            IF CC JUMP sawtoothgen;
            R0 = 0;
	    JUMP sawtoothgen;
