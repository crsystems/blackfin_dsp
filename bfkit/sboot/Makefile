# Makefile for bfkit sboot (serial boot loader)

TOOLPATH = ~/bfin-elf/bin
AS = $(TOOLPATH)/bfin-elf-as
CC = $(TOOLPATH)/bfin-elf-gcc
LD = $(TOOLPATH)/bfin-elf-ld
CCFLAGS = -g -O2 -Wall
INCPATH = ../include
LIBPATH = ../lib

all: sboot.hex

sboot.o: sboot.S
	$(CC) -c -I $(INCPATH) $<

sboot.x: sboot.o
	$(LD) -T ./sboot.ldf -o $@ $(LIBPATH)/bfinit.o $<

sboot.hex: sboot.x
	$(TOOLPATH)/bfin-elf-objcopy -O ihex $< $@
	
run:
	cat sboot.hex > /dev/ttyS0

clean:
	rm -f *.o *.x *.hex
