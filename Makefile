TARGET := v9kramtest
ROMS = $(TARGET).hex $(TARGET)_FE.bin $(TARGET)_FF.bin $(TARGET)_FE.hex $(TARGET)_FF.hex

.DEFAULT: all
all: $(TARGET).bin $(ROMS)

# create a user name to indicate who compiled this
USER_ID := $(shell gh api user -q ".login" 2>/dev/null || git config --get user.email 2>/dev/null || echo local_user)
$(info -- $(USER_ID) --)

# get a branch name if it is not main or master
BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo local)
ifeq ($(BRANCH),main)
BRANCH :=
endif
ifeq ($(BRANCH),master)
BRANCH :=
endif
ifneq ($(BRANCH),)
BRANCH := $(BRANCH)/
endif

# create a version string, including branch if it is not main or master

ifndef VERSION
VERSION := $(BRANCH)$(shell git describe 2>/dev/null || echo local_build)
endif
ifeq ($(VERSION),)
VERSION := local
endif

# print the version string if this is not a make restart
$(if $(MAKE_RESTARTS),,$(info -- $(TARGET) $(VERSION) --)$(info ))

# functions to create define options for nasm
defined = $(findstring undefined,$(origin $(1)))
DEFLIST = VERSION SHOWSTACK
# export $(DEFLIST)
VARDEF = $(if $(call defined,$(1)),,-d$(1)$(if $(value $(1)),="$(value $(1))"))

DEFS := $(foreach var,$(DEFLIST),$(call VARDEF,$(var)))


INC := -iinc

vpath % inc

SRC := $(TARGET).asm

NASM := nasm
MAME := /root/bldmame1/mame
#MAME := $(HOME)/Git/mame/v9kemu
SHASUM := shasum

RAM = 896
SERIAL = pty
#SERIAL = null_modem -bitb socket.localhost:7201
ROMPATH = $(HOME)/mrom
FE_NAME= "v9000 univ. fe f3f7 13db.7j"
FF_NAME= "v9000 univ. ff f3f7 39fe.8j"
export RAM SERIAL BREAK FLAGS

%.bin: %.asm %.dep Makefile
	$(NASM) $(INC) -f bin -o $@ -l $(@:%.bin=%.lst) -Lm $(DEFS) $<
	$(info )
	@tools/size $(@:%.bin=%.map)
	@$(SHASUM) $@

$(ROMS): $(TARGET).bin

roms:
#	split -b 4k $(TARGET).bin $(TARGET)_
#	mv $(TARGET)_aa $(TARGET)_FE.bin
#	mv $(TARGET)_ab $(TARGET)_FF.bin

#	cp $(TARGET).bin $(TARGET)_2716.bin
#	cat 2048.pad $(TARGET).bin > $(TARGET)_2732.bin
#	cat 2048.pad 2048.pad 2048.pad $(TARGET).bin  > $(TARGET)_2764.bin

	cat $(TARGET).bin > $(TARGET)_2732.bin
	cat 2048.pad 2048.pad $(TARGET).bin  > $(TARGET)_2764.bin
	$(info )
	$(info )

tidy:
	rm -f $(ROMS) $(TARGET).bin $(TARGET).lst $(TARGET).map $(TARGET).debug

clean: tidy
	rm -f $(TARGET).dep

%.dep: %.asm
	$(NASM) $(INC) -M -MF $@ -MT $@ $< 

%.map: %.bin
	@true

%.debug: %.map
	tools/make_debugscript $< > $@

debug: DEBUG = -debug
debug: $(TARGET).debug run

run: all
	rm -f comments/victor9k.cmt
#	cp $(TARGET)_FE.bin $(ROMPATH)/victor9k/$(FE_NAME)
	cp $(TARGET)_2732.bin $(ROMPATH)/victor9k/$(FF_NAME)
	$(MAME) victor9k -inipath ./test -rompath $(ROMPATH) -rs232a $(SERIAL) -ramsize $(RAM)K $(DEBUG) $(FLAGS)

.PHONY: all binaries clean run version debug deps
.NOTINTERMEDIATE:

all: $(ROMS) roms

deps: $(TARGET).dep
-include $(TARGET).dep