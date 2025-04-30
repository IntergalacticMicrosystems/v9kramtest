TARGET := v9kramtest

ifndef VERSION
VERSION := $(shell git describe 2>/dev/null || echo local_build)
endif
ifeq ($(VERSION),)
VERSION := local_build
endif

$(if $(MAKE_RESTARTS),,$(info -- $(TARGET) $(VERSION) --)$(info ))

ROMS = $(TARGET)_FE.bin $(TARGET)_FF.bin $(TARGET)_FE.hex $(TARGET)_FF.hex

defined = $(findstring undefined,$(origin $(1)))

DEFLIST = VERSION SHOWSTACK
# export $(DEFLIST)

VARDEF = $(if $(call defined,$(1)),,-d$(1)$(if $(value $(1)),="$(value $(1))"))

DEFS := $(foreach var,$(DEFLIST),$(call VARDEF,$(var)))

INC := -iinc

vpath % inc

SRC := $(TARGET).asm

NASM := nasm
#MAME := mame
MAME := $(HOME)/Git/mame/v9kemu

RAM = 256
#SERIAL = pty
SERIAL = null_modem -bitb socket.localhost:7201
ROMPATH = $(HOME)/.mame/roms
FE_NAME= "v9000 univ. fe f3f7 13db.7j"
FF_NAME= "v9000 univ. ff f3f7 39fe.8j"
export RAM SERIAL BREAK FLAGS


%.bin: %.asm Makefile
	$(NASM) $(INC) -f bin -o $@ -l $(@:%.bin=%.lst) -Lm $(DEFS) $<
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

$(TARGET).dep: $(SRC)
	$(NASM) $(INC) -M -MF $@ -MT $(TARGET).bin $<

$(TARGET).map: $(TARGET).bin

$(TARGET).debug: $(TARGET).map
	tools/make_debugscript $< > $@

debug: DEBUG = -debug
debug: all $(TARGET).debug run

run: all
	rm -f comments/victor9k.cmt
	cp $(TARGET)_FE.bin $(ROMPATH)/victor9k/$(FE_NAME)
	cp $(TARGET)_FF.bin $(ROMPATH)/victor9k/$(FF_NAME)
	$(MAME) victor9k -inipath ./test -rompath $(ROMPATH) -rs232a $(SERIAL) -ramsize $(RAM)K $(DEBUG) $(FLAGS)

.PHONY: binaries clean run $(TARGET).map version debug deps
.DEFAULT: all

all: $(ROMS)

deps: $(TARGET).dep
-include $(TARGET).dep