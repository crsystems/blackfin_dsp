# bfkit example blink program for the gnu blackfin assembler
#
# bfin-elf-as -o blink.o blink.asm
# bfin-elf-ld -T bfkit.ini -o blink.obj blink.o
# bfin-elf-objcopy -O ihex blink.obj blink.hex
#
# The boot loader will initialize SP and clocks:
# SP=0xFFB01000, CCLK=384.000MHz, SCLK=96.000MHz
#
# (C) 2007, ISI/ETH Zurich, strebel@isi.ee.ethz.ch, bolliger@isi.ee.ethz.ch

.text

# Die LEDs sind an den Pins PF4 und PF5 angeschlossen (ein Schema der Hardware
# sollte im Koffer dabei sein). Von Port F koennen die einzelnen Pins sowohl als
# Input als auch als Output benutzt werden, jedoch muss dem Prozessor mitgeteilt
# werden welchen Pin wir wie benutzen wollen. Durch setzen der entsprechenden
# Bits im FIO_DIR Register koennen wir das tun (Siehe Hardware Manual, Sektion 14-5).
# In der Programming Reference ab Sektion 8-37 ist beschrieben, wie der Inhalt
# eines Datenregisters (R0..R7) mit Hilfe eines Pointer Registers (P0...P7) in
# den Speicher geschrieben werden kann.
# Hinweis: P0.L (Low Data Half) bezeichnet die unteren 2 Bytes von P0
#          P0.H (High Data Half) bezeichnet die oberen 2 Bytes von P0
P0.H = 0xFFC0;         # FIO_DIR befindet sich an der Speicheradresse 0xFFC00730
P0.L = 0x0730;
R0.L = 0x0030;         # Setze Bit 4 und 5 in R0.L auf 1, die anderen Bits auf 0
W[P0] = R0;            # Programming Reference Sektion 8-49
SSYNC;                 # System Synchronize, Programming Reference Sektion 16-8

# Der Zustand der Pins des Port F ist im Register FIO_FLAG_D (Hardware Manual Sektion
# 14-8) gespeichert. Durch aendern der entsprechenden Bits dieses Registers
# koennen wir die Ausgangsspannung der einzelnen Pins setzen und somit die LEDs
# ein- und ausschalten (1=off, 0=on).
P0.H = 0xFFC0;         # Setze P0 auf die Adressen von FIO_FLAG_D
P0.L = 0x0700;
R0.L = 0x0010;         # LEDA on (PF5=0), LEDB off (PF4=1)
W[P0] = R0;
SSYNC;

loop1:                 # overall loop

# Um einen Loop zu programmieren muss zuerst ein Loop Counter (LC) gesetzt
# werden. Bei jedem Durchlauf wird der Counter dekrementiert, und sobald LC=0
# bricht der Loop ab und das Programm wird fortgesetzt. 
# Den Syntax zur Initialisierung eines Loops findet ihr im Programming Manual
# in Sektion 7-13 und folgende
R0.H = 0x16E3;         # 1s @384.000MHz
R0.L = 0x6000;
R0 >>= 1;	       # Faktor 1/2 => doppelt so schnelles Blinken
LC0 = R0;
LOOP delay1 LC0;        
LOOP_BEGIN delay1;
NOP;		       # Programming Manual Sektion 16-25
LOOP_END delay1;

CALL checkButtonA;

# Lies im Hardware Manual die Sektion 14-10 und folgende und finde heraus wozu
# FIO_FLAG_T gebraucht werden kann.
P0.H = 0xFFC0;         # FIO_FLAG_T
P0.L = 0x070C;
R0.L = 0x0030;         
W[P0] = R0;
SSYNC;

JUMP loop1;

checkButtonA:
P0.H = 0xFFC0;         # Setze P0 auf die Adressen von FIO_FLAG_D
P0.L = 0x0700;
R0.L = W[P0];
CC = !BITTST(R0,7);
IF CC JUMP checkButtonA;
RTS;
