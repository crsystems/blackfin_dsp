# Makefile for bfkit example

NAME = filter
TOOLPATH = ../../bfin-elf/bin
CC = $(TOOLPATH)/bfin-elf-gcc
LD = $(TOOLPATH)/bfin-elf-ld
INCPATH = ../include

all: $(NAME).hex

$(NAME).o: 
	$(CC) -c -I $(INCPATH) -o ./bin/$@ ./src/$(NAME).S

codec.o:
	$(CC) -c -I $(INCPATH) -o ./bin/$@ ./src/codec.S

uart.o: 
	$(CC) -c -I $(INCPATH) -o ./bin/$@ ./src/uart.S

exec.o:	
	$(CC) -c -I $(INCPATH) -o ./bin/$@ ./src/exec.S

$(NAME).x: $(NAME).o codec.o uart.o exec.o
	$(LD) -T $(INCPATH)/bfkit.ldf -o ./bin/$@ ./bin/$(NAME).o ./bin/codec.o ./bin/uart.o ./bin/exec.o

$(NAME).hex: $(NAME).x
	$(TOOLPATH)/bfin-elf-objcopy -O ihex ./bin/$(NAME).x ./bin/$@

run: $(NAME).hex
	../tools/bflod -x ./bin/$(NAME).hex

clean:
	rm -f ./bin/* *~
