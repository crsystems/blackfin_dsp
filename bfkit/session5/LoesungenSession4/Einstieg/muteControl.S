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

main:       R0 = 0 (Z);              // initialize codec using mic in
            CALL inicodec;
            R7.L = 0x04F9;           // 0dB volume level for left channel
            R7.H = 0x06F9;           // 0dB volume level for right channel
            R6.L = 0x04B0;           // -73dB volume level for left channel (muted)
            R6.H = 0x06B0;           // -73dB volume level for right channel (muted)

mloop:      CALL keycka;
            R0 = R7.L (Z);
            IF !CC JUMP leftison;
            R0 = R6.L (Z);
leftison:   CALL trspi;
            CALL keyckb;
            R0 = R7;
            IF !CC JUMP rightison;
            R0 = R6;
rightison:  R0 >>= 16;
            CALL trspi;
            CALL rxsport;
            CALL txsport;
            CALL rxsport;
            CALL txsport;
            JUMP mloop;

// not debounced key check, return with CC=1 if key a is pressed
keycka:     [--SP] = (R7:7, P5:5);   // save registers
            P5.H = HI(FIO_FLAG_D);   // read key input
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5] (Z);
            CC = !BITTST(R7,7);
            (R7:7, P5:5) = [SP++];   // restore registers
            RTS;

// not debounced key check, return with CC=1 if key b is pressed
keyckb:     [--SP] = (R7:7, P5:5);   // save registers
            P5.H = HI(FIO_FLAG_D);   // read key input
            P5.L = LO(FIO_FLAG_D);
            R7 = W[P5] (Z);
            CC = !BITTST(R7,6);
            (R7:7, P5:5) = [SP++];   // restore registers
            RTS;
