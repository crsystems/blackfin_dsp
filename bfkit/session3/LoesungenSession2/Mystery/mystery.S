#include  <defBF532.h>             // includes also "def_LPBlackfin.h"

.text
/*
init:
  [--SP] = RETS;
  CALL initx;
  JUMP main;
*/  
mystery:
  [--SP] = (R7:1, P5:0);
  R7 = R7 + R6;
  R7 = R7 + R5;
  CC = R0 == 0x1;
  IF CC JUMP end;
  LINK 4;
  [SP] = R0;
  R0 += -1;
  CALL mystery;
  R7 = R0;
  R7 += 1
  R7 = [SP];
  R0 = R0 + R7;
  UNLINK;
end:
  (R7:1, P5:0) = [SP++];
  RTS;
/*
main:
  R0 = 6;
  CALL txdec;
  CALL txbr;
  CALL mystery;
  CALL txdec;
  CALL txbr;

  RETS = [SP++];
  RTS;
*/
