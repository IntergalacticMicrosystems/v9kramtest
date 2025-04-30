TARGET := v9kramtest

ROMS = $(TARGET)_FE.bin $(TARGET)_FF.bin $(TARGET)_FE.hex $(TARGET)_FF.hex

INC := -iinc

SRC := $(TARGET).asm

NASM := nasm
MAME := mame

RAM = 256
SERIAL = pty
#SERIAL = null_modem -bitb socket.localhost:7201
ROMPATH = $(HOME)/.mame/roms
FE_NAME= "v9000 univ. fe f3f7 13db.7j"
FF_NAME= "v9000 univ. ff f3f7 39fe.8j"
export RAM SERIAL BREAK FLAGS


%.bin: %.asm
	$(NASM) $(INC) -f bin -o $@ -l $(@:%.bin=%.lst) -Lm $<
	$(info )
	@tools/size $(@:%.bin=%.map)

$(ROMS): $(TARGET).bin
	split -b 4k $(TARGET).bin $(TARGET)_
	mv $(TARGET)_aa $(TARGET)_FE.bin
	mv $(TARGET)_ab $(TARGET)_FF.bin
	$(info )
#	bin2hex -q -o $(TARGET).hex $(TARGET).bin
#	bin2hex -q -o $(TARGET)_FE.hex $(TARGET)_FE.bin
#	bin2hex -q -o $(TARGET)_FF.hex $(TARGET)_FF.bin
	$(info )

clean:
	rm -f $(ROMS) $(TARGET).bin $(TARGET).lst $(TARGET).map $(TARGET).debug $(TARGET).dep

$(TARGET).bin: version.inc

version.inc: VERSION = $(shell git describe 2>/dev/null || echo local_build)

version.inc: $(SRC) Makefile
	$(info Building $(TARGET) $(VERSION))
	@echo 'db "'$(VERSION)'"' > $@

$(TARGET).dep: $(SRC)
	$(NASM) $(INC) -M -MF $@ -MT $(TARGET).bin $<

$(TARGET).map: $(TARGET).bin

$(TARGET).debug: $(TARGET).map
	tools/make_debugscript $< > $@

debug: all $(TARGET).debug
	tools/run -debug $(FLAGS)

run: all
	rm -f comments/victor9k.cmt
	cp $(TARGET)_FE.bin $(ROMPATH)/victor9k/$(FE_NAME)
	cp $(TARGET)_FF.bin $(ROMPATH)/victor9k/$(FF_NAME)
	mame victor9k -inipath ./test -rompath $(ROMPATH) -rs232a $(SERIAL) -ramsize $(RAM) $(FLAGS)

.PHONY: binaries clean run $(TARGET).map
.DEFAULT: all

all: $(ROMS)

-include $(TARGET).dep