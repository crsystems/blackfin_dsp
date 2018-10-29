/**************************************************************************
pass.S: audio passthrough example using codec.o

Compilation: bfin-elf-gcc -c -I ../include pass.S
Linking:     bfin-elf-ld -T ../include/bfkit.ldf -o pass.x pass.o codec.o

(C) 2008, ISI/ETH Zurich, bolliger@isi.ee.ethz.ch
**************************************************************************/

#include    <defBF532.h>             // includes also "def_LPBlackfin.h"

.text

init:       [--SP] = RETS;           // push RETS to allow nested calls
            JUMP main;               // jump to main program

main:       R0 = 1 (Z);              // initialize codec using mic in
            CALL inicodec;
  

mloop:      CALL rxsport;            // receive right channel
            CALL txsport;            // transmit right channel
            CALL rxsport;            // receive left channel
            CALL txsport;            // transmit left channel
            JUMP mloop;              // loop forever
