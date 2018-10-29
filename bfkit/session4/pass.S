/**************************************************************************
pass.S: audio passthrough example using codec.o

Compilation: bfin-elf-gcc -c -I ../include pass.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o pass.x pass.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"
#define	KEYHIT	50000
#define HP_MAX  0x7F
.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       R0 = 0 (Z);              // initialize codec using mic in
            CALL inicodec;
	    R1.L = 0x0479;			//default headphone values
	    R2.L = 0x0679;  



mloop: 
	    	CALL rxsport;
		CALL txsport;
		CALL rxsport;
		CALL txsport;
		CALL keycka;
	    	IF CC JUMP left_shift;
key_a:
	    	CALL keyckb;
	    	IF CC JUMP right_shift;
key_b:
    	    	JUMP mloop;              // loop forever







aloop:
		CALL rxsport;
		CALL txsport;
		CALL rxsport;
		CALL txsport;
		CALL keycka;
	    	IF !CC JUMP mloop;
    	    	JUMP aloop;

 
bloop:
		CALL rxsport;
		CALL txsport;
		CALL rxsport;
		CALL txsport;
		CALL keyckb;
	    	IF !CC JUMP mloop;
    	    	JUMP bloop;

left_shift:
		R4 = 0x047F;
		CC = R1 < R4;
		IF !CC JUMP key_a;
		R1 += 1;
		R2 += -1;
		R0 = R1
		CALL trspi;

		R0 = R2;
		CALL trspi;

		JUMP aloop;

right_shift:
		R4 = 0x067F;
		CC = R2 < R4;
		IF !CC JUMP key_b;
		R1 += -1;
		R2 += 1;
		
		R0 = R1;
		CALL trspi;

		R0 = R2;
		CALL trspi;

		JUMP bloop;

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

