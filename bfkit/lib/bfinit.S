/****************************************************************************

bfinit.S: initialize bfkit (stack, clock, mode, handlers)

After initialization _main is called from the lowest priority interrupt
to stay in supervisor mode and still keep other interrupts serviced.

building bfinit.o:
bfin-elf-gcc -c -I ../include bfinit.S

compiling user code (c or assembler):
bfin-elf-gcc -c -I ../include myprog.c

linking: (use linker script bfkit.ldf, bfinit.o is the first object)
bfin-elf-ld -T bfkit.ldf -o myprog bfinit.o myprog.o

(C) 2007, ISI/ETH Zurich, strebel@isi.ee.ethz.ch
****************************************************************************/

#define  __ADSPLPBLACKFIN__     // get rid of warning in "defBF532.h"
#include <defBF532.h>           // includes "def_LPBlackfin.h"

#define  STACK    0xFFB01000    // top of 4k scratch memory

.text

// start is the entry point of the code executed after reset
.global start
start:

SP.H = HI(STACK);               // initialize stack pointer
SP.L = LO(STACK);
FP = SP;

P0.H = HI(FIO_FLAG_D);          // programmable flags data
P0.L = LO(FIO_FLAG_D);
R0.L = 0x003F;                  // LEDs off=high, SPISEL 3..0 high
W[P0] = R0;
SSYNC;

P0.H = HI(FIO_DIR);             // programmable flags direction
P0.L = LO(FIO_DIR);
R0.L = 0x003F;                  // LEDs + SPISEL 3..0 outputs
W[P0] = R0;
SSYNC;

P0.H = HI(FIO_INEN);            // programmable flags direction
P0.L = LO(FIO_INEN);
R0.L = 0x00C0;                  // enable inputs for keys
W[P0] = R0;
SSYNC;

// clock setup: PLL_CTL takes effect in IDLE state
// PLL wakeup is enabled in SIC_IWR after reset

P0.H = HI(PLL_CTL);             // init PLL for full speed
P0.L = LO(PLL_CTL);
R0.L = 0x4000;                  // 32 * 12.000 = 384.000 MHz
W[P0] = R0;
SSYNC;

CLI R0;                         // interrupts off, save IMASK to R0
IDLE;                           // wait for PLL wakeup
STI R0;                         // restore IMASK from R0

P0.H = HI(PLL_DIV);             // CCLK and SCLK dividers
P0.L = LO(PLL_DIV);
R0.L = 0x0004;                  // CCLK = VCO/1, SCLK = VCO/4
W[P0] = R0;
SSYNC;

// install default handlers
// to stay in supervisor mode and still keep interrupts serviced
// lowest priority interrupt 15 is installed to handle mainprog

P0.H = HI(EVT2);                // interrupt vectors
P0.L = LO(EVT2);
P1.H = nhandler;
P1.L = nhandler;
[P0++] = P1;                    // int2 (nmi)
P1.H = xhandler;
P1.L = xhandler;
[P0++] = P1;                    // int3 (exception)
P1.H = ihandler;
P1.L = ihandler;
[P0++] = P1;                    // int4 (reserved)
[P0++] = P1;                    // int5 (hardware)
[P0++] = P1;                    // int6 (core timer)
[P0++] = P1;                    // int7
[P0++] = P1;                    // int8
[P0++] = P1;                    // int9
[P0++] = P1;                    // int10
[P0++] = P1;                    // int11
[P0++] = P1;                    // int12
[P0++] = P1;                    // int13
[P0++] = P1;                    // int14
P1.H = mainprog;
P1.L = mainprog;
[P0++] = P1;                    // int15 (lowest priority)

R0 = EVT_IVG15 (Z);             // enable int 15
STI R0;

RAISE 15;                       // envoke int 15
P0.H = waitloop;                // set return address for current event
P0.L = waitloop;
RETI = P0;
RTI;                            // return from reset event

waitloop:
JUMP waitloop;

mainprog:
[--SP] = RETI;                  // push RETI to allow other interrupts
P0.H = _main;                   // address of main() in c program
P0.L = _main;
CALL (P0);                      // ... main() ...
P0.H = HI(WDOG_CTL);            // RESET: disable watchdog timer 
P0.L = LO(WDOG_CTL);
R0.L = 0x0AD0;
W[P0] = R0;
SSYNC;
P0.H = HI(WDOG_CNT);            // small count to watchdog timer 
P0.L = LO(WDOG_CNT);
R0.H = 0x0010;                  // 0x00100000 SCLKs (ca 11ms)
R0.L = 0x0000;                  // to finish pending serial tx
[P0] = R0;
SSYNC;
P0.H = HI(WDOG_CTL);            // enable watchdog timer for reset
P0.L = LO(WDOG_CTL);
R0.L = 0x0000;
W[P0] = R0;
SSYNC;
JUMP waitloop;                  // wait for watchdog reset

nhandler:
R0.L = 0x0020;                  // led A
JUMP error;
RTN;

xhandler:
R0.L = 0x0010;                  // led B
JUMP error;
RTX;

ihandler:
R0.L = 0x0030;                  // led A+B
JUMP error;
RTI;

error:
P0.H = HI(FIO_FLAG_S);          // programmable flags set
P0.L = LO(FIO_FLAG_S);
R1.L = 0x003F;                  // leds off, SPISEL 3..0 high
W[P0] = R1;
SSYNC;
P0.H = HI(FIO_FLAG_C);          // programmable flags clear
P0.L = LO(FIO_FLAG_C);
W[P0] = R0;                     // leds in R0 on
SSYNC;
JUMP waitloop;

