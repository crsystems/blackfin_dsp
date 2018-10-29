/**************************************************************************
hello.S: 'Hello World' example in assembler code

Compilation: bfin-elf-gcc -c -I ../inc hello.S

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"

.data
.section    .rodata
titl:       .string "\r\nHello World! (press 'q' to quit)\r\n";
term:       .string "\r\nbyebye ...\r\n";

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       CALL initx;

hello:      P0.H = titl;
            P0.L = titl;
            CALL txstr;

mloop:      CALL rxchr;
            IF !CC JUMP mloop;
            R1 = 'q'(Z);                // 'q' --> quit
            CC = R0 == R1;
            IF CC JUMP mexit;

            JUMP mloop;


mexit:      P0.H = term;
            P0.L = term;
            CALL txstr;
            R0 = 27(Z);
            CALL txchr;
            RETS = [SP++];
            RTS;

