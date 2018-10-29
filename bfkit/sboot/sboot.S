/**************************************************************************

sboot.S: serial boot loader for bfkit (BF532).

(C) 2007, ISI/ETH Zurich, strebel@isi.ee.ethz.ch

***************************************************************************

Allows asynchronous serial receive of intel hex records.
The code is executed after the eof record is received.

To send a hex file from a Linux host simply execute:
cat hexfile > /dev/tty...

The two LEDs are flashed for 100ms at program start.
An address extension record (expected first) inverts one LED.
Every data record toggles both LEDs. When an error occurs both
LEDs are turned on. Successful program upload turns LEDs off.

intel hex file format:

 number of data bytes
 | address field
 | |   record type (00=data 01=eof 02=segment 04=addrext 05=entry)
 | |   | nn bytes of data
 | |   | |       checksum (completion to zero)
 | |   | |       |
:nnaaaattddddddddcc

The UART is initialized for 9600bps, 8 bits, no parity, 1 stop;
but the baudrate can be changed with a customized record.
The record is acknowledged with a '!' before the change.

 data count = 00
 | address field = SCLK/16/baudrate
 | |   record type = 0F
 | |   | checksum
 | |   | |
:0002710F7E (9600bps default)
:0001380FB8 (approx. 19200bps)
:00009C0F55 (approx. 38400bps)
:0000680F89 (approx. 57600bps)
:0000340FBD (approx. 115200bps)

The same record type with an address 0 can be used to initialize the
optional 32MB SDRAM (the supply current will increase about 30mA).
This is necessary BEFORE loading code or initialized data to SDRAM.

:0000000FF1 (initialize external SDRAM)

'sboot' is loaded from an external SPI flash to the top 1kB of
BF532 L1 code memory (FFA13C00 .. FFA13FFF) in boot mode 3.
User code must fit into the 47kB below (FFA08000 .. FFA13FFF)
when using only internal memory.

Building: (linker script sboot.ldf to relocate for FFA13C00)
bfin-elf-gcc -c -I ../include sboot.S
bfin-elf-ld -T ./sboot.ldf -o sboot.x bfinit.o sboot.o
bfin-elf-objcopy -O ihex sboot.x sboot.hex

**************************************************************************/

#define  __ADSPLPBLACKFIN__     // get rid of warning in "defBF532.h"
#include <defBF532.h>           // includes "def_LPBlackfin.h"

#define  TBYTE    0xFF907FFF    // top of L1 data bank B
#define  SCLK     96000000      // SCLK after clock setup

.text                           // at FFA13C00

// _main is called from bfinit in supervisor mode
.global _main
_main:

[--SP] = RETS;                  // calls will change RETS
R3.L = SCLK/16/9600;            // UART to 9600,8,N,1
CALL inituart;

P5 = 0(Z);                      // P5 keeps start address
P4 = 0(Z);                      // P4 keeps current load address
P3.H = HI(UART_LSR);            // P3 points to line status
P3.L = LO(UART_LSR);
P2.H = HI(UART_RBR);            // P2 points to tx/rx buffer
P2.L = LO(UART_RBR);
R7 = 0(Z);                      // R7 keeps the checksum
R6 = 0(Z);                      // R6 keeps the record type
R5 = 0(Z);                      // R5 keeps the data count

// blink to say hello
P0.H = HI(FIO_FLAG_C);          // programmable flags clear
P0.L = LO(FIO_FLAG_C);
R0.L = 0x0030;                  // LEDs A+B on
W[P0] = R0;
SSYNC;

P0.H = HI(4*SCLK/10);           // 1/10s delay
P0.L = LO(4*SCLK/10);
LSETUP(delay, delayx) LC0 = P0;
delay:
delayx: NOP;

P0.H = HI(FIO_FLAG_S);          // programmable flags set
P0.L = LO(FIO_FLAG_S);
R0.L = 0x0030;                  // LEDs A+B off
W[P0] = R0;
SSYNC;

bolo:                           // parse intel hex records
CALL rxchar;                    // wait for ':'
R1 = ':'(Z);
CC = R0 == R1;
IF !CC JUMP bolo;
CALL rxhex;
R5 = R0;                        // data count
CALL rxhex;
R3 = R0 << 8;                   // load address hi
CALL rxhex;
R3 = R3 | R0;                   // load address lo
CALL rxhex;
R6 = R0;                        // record type
R0 = 0x0F(Z);
CC = R6 == R0;                  // baud rate change type?
IF !CC JUMP tchk0;
R0 = 0(Z);
CC = R5 == R0;                  // data count 0?
IF !CC JUMP error;
CALL rxhex;                     // get checksum
CC = R7 == 0;                   // ok?
IF !CC JUMP error;
R0.L = '!';
CALL txchar;
CC = R3 == 0;                   // init SDRAM?
IF !CC JUMP chgbaud;
inisdram:                       // 48LC16M16A2-75 32MB SDRAM
P0.H = HI(EBIU_SDRRC);          // SDRAM Refresh Rate Control Register
P0.L = LO(EBIU_SDRRC);
R0 = 0x0741(Z);                 // 96M * 64m / 8192 - 6 - 3
W[P0] = R0;
SSYNC;
P0.L = LO(EBIU_SDBCTL);         // SDRAM Memory Bank Control Register
R0 = 0x0013(Z);                 // EBCAW=9, EBSZ=32MB, EBE
W[P0] = R0;
SSYNC;
P0.L = LO(EBIU_SDGCTL);         // SDRAM Memory Global Control Register
R0.H = 0x0091;                  // TWR=2 TRCD=3 TRP=3 TRAS=6 CAS=3
R0.L = 0x998D;
[P0] = R0;
SSYNC;
JUMP bolo;
chgbaud:
R1.L = W[P3];                   // read line status
CC = BITTST(R1,6);              // until tx complete
IF !CC JUMP chgbaud;
CALL inituart;                  // activate new baud rate
JUMP bolo;
tchk0:
CC = R6 == 0;                   // data type?
IF !CC JUMP tchk1;
P0.H = HI(FIO_FLAG_T);          // programmable flags toggle
P0.L = LO(FIO_FLAG_T);
R0.L = 0x0030;                  // LEDs A+B change
W[P0] = R0;
SSYNC;
R4 = P4;                        // adjust address pointer
R4.L = 0x0000;
R4 = R4 | R3;
P4 = R4;
nextbt:
CC = R5 == 0;                   // while data available
IF CC JUMP sumck;
CALL rxhex;
CALL putcode;
P4 += 1;
R5 += -1;
JUMP nextbt;
tchk1:
CC = R6 == 1;                   // eof type?
IF !CC JUMP tchk4;
P0.H = HI(FIO_FLAG_S);          // programmable flags set
P0.L = LO(FIO_FLAG_S);
R0.L = 0x0030;                  // LEDs A+B off
W[P0] = R0;
SSYNC;
CALL (P5);                      // execute the received code
RETS = [SP++];
RTS;                            // back to bfinit (-->reset)
tchk4:
R0 = 4(Z);
CC = R6 == R0;                  // address extension type?
IF !CC JUMP tchk5;
P0.H = HI(FIO_FLAG_T);          // programmable flags toggle
P0.L = LO(FIO_FLAG_T);
R0.L = 0x0020;                  // LED A change
W[P0] = R0;
SSYNC;
CC = R5 == 2;                   // data count 2?
IF !CC JUMP error;
CALL rxhex;
R3 = R0 << 8;                   // extended address hi
CALL rxhex;
R3 = R3 | R0;                   // extended address lo
R3 <<= 16;                      // adjust address pointer
P4 = R3;
JUMP sumck;
tchk5:
R0 = 5(Z);
CC = R6 == R0;
IF !CC JUMP error;              // unknown record type
R0 = 4(Z);
CC = R5 == R0;                  // data count 4?
IF !CC JUMP error;
CALL rxhex;
R3 = R0;                        // upper half address hi
CALL rxhex;
R3 <<= 8;
R3 = R3 | R0;                   // upper half address lo
CALL rxhex;
R3 <<= 8;
R3 = R3 | R0;                   // lower half address hi
CALL rxhex;
R3 <<= 8;
R3 = R3 | R0;                   // lower half address lo
P5 = R3;
JUMP sumck;
sumck:
CALL rxhex;
CC = R7 == 0;                   // checksum ok?
IF CC JUMP bolo;
error:
P0.H = HI(FIO_FLAG_C);          // programmable flags clear
P0.L = LO(FIO_FLAG_C);
R0.L = 0x0030;                  // LEDs A+B on
W[P0] = R0;
SSYNC;
CLI R0;                         // interrupts off, save IMASK to R0
IDLE;                           // idle to save power
STI R0;                         // restore IMASK from R0
JUMP error;

.align 4
inituart:                       // baud rate divisor in R3.L
P0.H = HI(UART_LCR);            // line control
P0.L = LO(UART_LCR);
R0.L = 0x0080;                  // enable access to DLL/DLH
W[P0] = R0;
SSYNC;
R0 = R3;
P0.L = LO(UART_DLL);            // divisor latch low
W[P0] = R0;
SSYNC;
R0 >>= 8;
P0.L = LO(UART_DLH);            // divisor latch high
W[P0] = R0;
SSYNC;
P0.L = LO(UART_LCR);            // line control
R0.L = 0x0003;                  // 8 bits, 1 stop, no parity
W[P0] = R0;
SSYNC;
P0.L = LO(UART_GCTL);           // global control
R0.L = 0x0001;                  // enable UART clock
W[P0] = R0;
SSYNC;
P0.L = LO(UART_RBR);            // receive buffer register
R0.L = W[P0];                   // read to clear rx buffer
SSYNC;
RTS;

putcode:                        // use dma to write to l1 code ram
P0.H = HI(TBYTE);               // byte temporary to l1 data ram
P0.L = LO(TBYTE);
B[P0] = R0;
R0 = P0;                        // l1 data ram is source
P0.H = HI(MDMA_S0_START_ADDR);  // source start address
P0.L = LO(MDMA_S0_START_ADDR);
[P0] = R0;
R0 = P4;                        // destination in P4
P0.L = LO(MDMA_D0_START_ADDR);  // destination start address
[P0] = R0;
R0 = 1(Z);                      // 1 byte
P0.L = LO(MDMA_S0_X_COUNT);     // source byte count
W[P0] = R0;
P0.L = LO(MDMA_D0_X_COUNT);     // destination byte count
W[P0] = R0;
R0 = 1(Z);                      // 1 byte
P0.L = LO(MDMA_S0_X_MODIFY);    // source increment
W[P0] = R0;
P0.L = LO(MDMA_D0_X_MODIFY);    // destination increment
W[P0] = R0;
R0.L = 0x0001;                  // 8bit, dma_en
P0.L = LO(MDMA_S0_CONFIG);      // source config
W[P0] = R0;
R0.L = 0x0083;                  // 8bit, write, dma_en
P0.L = LO(MDMA_D0_CONFIG);      // destination config
W[P0] = R0;
P0.L = LO(MDMA_D0_IRQ_STATUS);  // destination dma status
waitdma:
R0 = W[P0];                     // wait for dma complete flag
CC = BITTST(R0,0);
IF !CC JUMP waitdma;
R0 = 1(Z);                      // clear flag
W[P0] = R0;
RTS;

rxhex:
[--SP] = RETS;                  // we call nested routines
CALL rxchar;
CALL hex2bin;
R2 = R0;
R2 <<= 4;                       // higher nibble
CALL rxchar;
CALL hex2bin;
R0 = R0 | R2;                   // lower nibble
R7 = R7 + R0;                   // update checksum
R2.L = 0x00FF;
R7 = R7 & R2;
RETS = [SP++];
RTS;

hex2bin:
R1 = '9'(Z);
CC = R0 <= R1;
IF !CC JUMP hexalph;
R1 = '0'(Z);
CC = R0 < R1;
IF CC JUMP error;
R0 = R0 - R1;
RTS;
hexalph:
BITSET(R0,5);                   // upper case to lower
R1.L = 'a';
CC = R0 < R1;
IF CC JUMP error;
R1.L = 'f';
CC = R0 <= R1;
IF !CC JUMP error;
R1.L = ('a'-10);
R0 = R0 - R1;
RTS;

rxchar:
R1.L = W[P3];                   // read line status
CC = BITTST(R1,0);
IF !CC JUMP rxchar;
R0 = W[P2](Z);                  // read rx buffer
RTS;

txchar:
R1.L = W[P3];                   // read line status
CC = BITTST(R1,5);
IF !CC JUMP txchar;
W[P2] = R0;                     // write tx buffer
RTS;

