ASM=wla-65816
LINK=wlalink
OBJ=\
	init.o\
	main.o\
	cons.o\
	sd.o\
	fs.o\
	fs2.o\
	name.o\

all: rom.mif

clean:
	rm -f $(OBJ)

rom.mif: rom.smc
	(echo -e  'DEPTH = 32768;\nWIDTH = 8;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN'; xxd -g 1 $< | sed 's/  .*$$/;/'; echo 'END;') > rom.mif

rom.smc: $(OBJ)
	( echo '[objects]' ; for i in $(OBJ); do echo $$i; done ) | $(LINK) /dev/stdin rom.smc

%.o: %.asm dat.inc
	$(ASM) -o $<
