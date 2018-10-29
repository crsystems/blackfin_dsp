# Makefile for bfkit bfinit (setup for C programmes)

TOOLPATH = ~/bfin-elf/bin
CC = $(TOOLPATH)/bfin-elf-gcc
CCFLAGS = -g -O2 -Wall
INCPATH = ../include

all: bfinit.o cinit.o 

bfinit.o: bfinit.S
	$(CC) $(CCFLAGS) -c -I $(INCPATH) $<

cinit.o: cinit.S
	$(CC) $(CCFLAGS) -c -I $(INCPATH) $<

clean:
	rm -f *.o
