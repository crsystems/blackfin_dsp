# 1 "debounce.S"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "debounce.S"
# 16 "debounce.S"
# 1 "../include/defBF532.h" 1
# 18 "../include/defBF532.h"
# 1 "../include/def_LPBlackfin.h" 1
# 19 "../include/defBF532.h" 2
# 17 "debounce.S" 2





.data

dkeya: .int 0

.text

init: [--SP] = RETS;
            P0.H = (((0xFFC00704) >> 16) & 0xFFFF);
            P0.L = ((0xFFC00704) & 0xFFFF);
            R0.L = 0x0010;
            W[P0] = R0;
            SSYNC;

            mloop:
            CALL keycka;
            IF !CC JUMP keyb;
            CALL ledAdd1;

            keyb:
            CALL keyckb;
            IF !CC JUMP mloop;
            RETS = [SP++];
            RTS;


keycka: [--SP] = (R7:5, P5:4);
            R6.H = (((50000) >> 16) & 0xFFFF);
            R6.L = ((50000) & 0xFFFF);
            P5.H = dkeya;
            P5.L = dkeya;

            P4.H = (((0xFFC00700) >> 16) & 0xFFFF);
            P4.L = ((0xFFC00700) & 0xFFFF);
            R5 = W[P4](Z);
            CC = !BITTST(R5,7);

            IF CC JUMP keyahit;
            R7 = 0(Z);
            JUMP writedkeya;

            keyahit:
            R7 = [P5];
            CC = R7 <= R6;
            IF !CC JUMP writedkeya;
            R7 += 1;

            writedkeya:
            [P5] = R7;
            CC = R6 == R7;
            (R7:5, P5:4) = [SP++];
            RTS;


keyckb: [--SP] = (R7:7, P5:5);
            P5.H = (((0xFFC00700) >> 16) & 0xFFFF);
            P5.L = ((0xFFC00700) & 0xFFFF);
            R7 = W[P5] (Z);
            CC = !BITTST(R7,6);
            (R7:7, P5:5) = [SP++];
            RTS;


ledAdd1: [--SP] = (R7:7, P5:5);
            P5.H = (((0xFFC00700) >> 16) & 0xFFFF);
            P5.L = ((0xFFC00700) & 0xFFFF);
            R7 = W[P5](Z);
            BITTGL(R7,4);
            CC = BITTST(R7,4);
            IF !CC JUMP ledupd;
            BITTGL(R7,5);

            ledupd:
            W[P5] = R7;
            (R7:7, P5:5) = [SP++];
            RTS;
