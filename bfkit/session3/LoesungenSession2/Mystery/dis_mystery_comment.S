
mystery.o:     file format elf32-bfin

Disassembly of section .text:

// Die Funktion mystery berechnet rekursiv die gausssche Summe fuer R0 = n. 
// Sie liefert das Resultat n*(n+1)/2 wieder in R0.

00000000 <mystery>:
// Das Sichern der Register R6 bis R1 sowie P5 bis P0 ist unnoetig, da diese nicht 
// veraendert werden.
   0:	c8 05       	[--SP] = (R7:1, P5:0);      
   2:	f7 51       	R7 = R7 + R6; 							// ueberfluessig
   4:	ef 51       	R7 = R7 + R5;								// ueberfluessig
   6:	08 0c       	CC = R0 == 0x1;
   8:	0d 18       	IF CC JUMP 0x22 <end>;
   a:	00 e8 01 00 	LINK 0x4;		/* (4) */
   e:	30 93       	[SP] = R0;
  10:	f8 67       	R0 += -0x1;		/* ( -1) */
  12:	ff e3 f7 ff 	CALL 0x0 <mystery>;
  16:	38 30       	R7 = R0;										// ueberfluessig
  18:	0f 64       	R7 += 0x1;		/* (  1) */		// ueberfluessig
  1a:	37 91       	R7 = [SP];
  1c:	38 50       	R0 = R0 + R7;
  1e:	01 e8 00 00 	UNLINK;

00000022 <end>:
  22:	88 05       	(R7:1, P5:0) = [SP++];
  24:	10 00       	RTS;
	...
