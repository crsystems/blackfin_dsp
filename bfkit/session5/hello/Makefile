# Makefile for bfkit hello example

NAME = hello
TOOLPATH = ~/bfin-elf/bin
CC = $(TOOLPATH)/bfin-elf-gcc
LD = $(TOOLPATH)/bfin-elf-ld
INCPATH = ../../include

all: $(NAME).hex

$(NAME).o: $(NAME).S
	$(CC) -c -I $(INCPATH) $<

uart.o: uart.S
	$(CC) -c -I $(INCPATH) $<

$(NAME).x: $(NAME).o uart.o
	$(LD) -T $(INCPATH)/bfkit.ldf -o $@ $^

$(NAME).hex: $(NAME).x
	$(TOOLPATH)/bfin-elf-objcopy -O ihex $< $@
	
run: $(NAME).hex
	../../tools/bflod -t $(NAME).hex

clean:
	rm -f *.o *.x *.hex *~
