# Makefile for bfkit example

NAME = communication_test
TOOLPATH = ~/bfin-elf/bin
CC = $(TOOLPATH)/bfin-elf-gcc
LD = $(TOOLPATH)/bfin-elf-ld
INCPATH = ~/p_s/blackfin_dsp/bfkit/include

all: $(NAME).hex

$(NAME).o: $(NAME).S
	$(CC) -c -I $(INCPATH) $<

codec.o: codec.S
	$(CC) -c -I $(INCPATH) $<

uart.o: uart.S
	$(CC) -c -I $(INCPATH) $<

exec.o: exec.S
	$(CC) -c -I $(INCPATH) $<

$(NAME).x: $(NAME).o codec.o uart.o exec.o
	$(LD) -T $(INCPATH)/bfkit.ldf -o $@ $^

$(NAME).hex: $(NAME).x
	$(TOOLPATH)/bfin-elf-objcopy -O ihex $< $@

run: $(NAME).hex
	~/p_s/blackfin_dsp/bfkit/tools/bflod -x $(NAME).hex

clean:
	rm -f *.o *.x *.hex *~
