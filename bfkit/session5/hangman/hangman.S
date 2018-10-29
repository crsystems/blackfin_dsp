/**************************************************************************
hangman.S: 'Hangman' example in assembler code

Compilation: bfin-elf-gcc -c -I ../inc hangman.S

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"

.data
.section    .rodata
sol:	    .string "solution";
len:

.data
tries:	    .int	10;



.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       CALL initx;

	    R0.H = 0x16E3; 	     // delay of 1s as a part of a workaround       
	    R0.L = 0x6000;
	    LC0 = R0;
	    LOOP delay1 LC0;        
	    LOOP_BEGIN delay1;
	    NOP;                  
	    LOOP_END delay1;

clearbuf:   CALL rxchr;		     // second part of the workaround
	    IF CC JUMP clearbuf;  
	    JUMP count_chars;
	

mloop:      CALL rxchr;
	    IF !CC JUMP mloop;
	    R1 = 127(Z);	     // on delete quit program		    
	    CC = R0 == R1;
	    IF CC JUMP gameover;
	    JUMP check_loop;

	    JUMP mloop;


check_char:
	    P0.H = sol;
	    P0.L = sol;
	    R2 = 0(Z);    
	
check_loop:
	    R1 = [P0];
	    R2 += 1;
	    CC = R1 == R0;

	    IF CC JUMP check_true;
	    CC = R2 <= R7;
	    R1 = B[P0++];

	    IF CC JUMP check_loop;
	    JUMP check_false;
	    
check_true:
	    R0 = 49(Z);
	    CALL txchr;
	    JUMP mloop;


check_false:
	    R0 = 48(Z);
	    CALL txchr;
	    JUMP mloop;





count_chars:
	    R0 = 0(Z);
	    P0.H = sol;
	    P0.L = sol;
	    R1 = P0;
	    P1.H = len;
	    P1.L = len;
	    R2 = P1;
count_loop: 	    
	    CC = R1 == R2;
	    IF CC JUMP count_done;	    
	    R0 += 1;
	    R1 += 1;
	    JUMP count_loop;

count_done: R7 = R0;
	    R0 += 47;
            CALL txchr;
            JUMP mloop;




gameover:   R0 = 27(Z);
            CALL txchr;
            RETS = [SP++];
            RTS;

