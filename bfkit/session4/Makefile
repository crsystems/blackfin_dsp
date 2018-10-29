# Makefile for bfkit codec example

NAME = pass
TOOLPATH = ~/bfin-elf/bin
CC = $(TOOLPATH)/bfin-elf-gcc
LD = $(TOOLPATH)/bfin-elf-ld
INCPATH = ../include

all: $(NAME).hex

$(NAME).o: $(NAME).S
	$(CC) -c -I $(INCPATH) $<

codec.o: codec.S
	$(CC) -c -I $(INCPATH) $<

$(NAME).x: $(NAME).o codec.o
	$(LD) -T $(INCPATH)/bfkit.ldf -o $@ $^

$(NAME).hex: $(NAME).x
	$(TOOLPATH)/bfin-elf-objcopy -O ihex $< $@
	
run: $(NAME).hex
	../tools/bflod $(NAME).hex

clean:
	rm -f *.o *.x *.hex *~
