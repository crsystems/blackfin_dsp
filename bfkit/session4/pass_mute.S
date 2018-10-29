/**************************************************************************
pass.S: audio passthrough example using codec.o

Compilation: bfin-elf-gcc -c -I ../include pass.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o pass.x pass.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
#define	KEYHIT	50000

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       R0 = 0 (Z);              // initialize codec using mic in
            CALL inicodec;
  

mloop: 
	    	CALL rxsport;
		CALL txsport;
		CALL rxsport;
		CALL txsport;
		CALL keycka;
	    	IF CC JUMP mute_left;
		JUMP unmute_left;
key_a:
	    	CALL keyckb;
	    	IF CC JUMP mute_right;
		JUMP unmute_right;
key_b:
    	    	JUMP mloop;              // loop forever


mute_left:
		R0.L = 0x0430;
	    	CALL trspi;
		JUMP key_a;

unmute_left:
		R0.L = 0x0479;
		CALL trspi;
		JUMP key_a; 

mute_right:
	    	R0.L = 0x0630;
	    	CALL trspi;
		JUMP key_b;

unmute_right:
		R0.L = 0x0679;
		CALL trspi;
		JUMP key_b;


keycka:
	    [--SP] = (R7:3, P5:4);

            P4.H = HI(FIO_FLAG_D);
            P4.L = LO(FIO_FLAG_D);
            R5 = W[P4](Z);
	    
	    CC = !BITTST(R5,7);      // CC = Is key A pressed?
            IF !CC JUMP l_exit;      // if key A pressed: jump

	    l_exit:
            (R7:3, P5:4) = [SP++];
            RTS;

keyckb:
	    [--SP] = (R7:3, P5:4);

            P4.H = HI(FIO_FLAG_D);
            P4.L = LO(FIO_FLAG_D);
            R5 = W[P4](Z);
            
	    
	    CC = !BITTST(R5,6);      // CC = Is key A pressed?
            IF !CC JUMP l1_exit;      // if key A pressed: jump

	    l1_exit:
            (R7:3, P5:4) = [SP++];
            RTS;

