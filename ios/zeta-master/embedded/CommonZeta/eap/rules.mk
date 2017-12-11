MCU = msp430g2303

CC = msp430-gcc
OBJCOPY = msp430-objcopy
SIZE = msp430-size
MSPDEBUG = mspdebug
MSP430FLASHER = MSP430Flasher
EMSTOOL = emstool
COPTS = -Os -Wall -fno-strict-aliasing -c -g -mmcu=$(MCU)
LDOPTS = -mmcu=$(MCU) -Wl,-Map=main.map

EMSOUT = $(SCHEMA)/out
RMFILES = *.out *.map *.hex *.obj
CFLAGS = -I$(COMMON) -I$(EMSOUT) $(COPTS)
LDFLAGS = $(LDOPTS)
VPATH = $(COMMON)
OUTFILE = main.out

all: $(OUTFILE)

ifeq (,$(findstring Windows,$(OS)))
load: out-check
	$(MSPDEBUG) rf2500 "prog $(OUTFILE)" 2>&1
else
load: $(OUTFILE:.out=.hex)
	$(MSP430FLASHER) -i USB -m AUTO -e ERASE_MAIN -n $(MCU) -w $< -v -z [VCC] -g
endif

$(OUTFILE): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^
	$(SIZE) $@

%.hex: out-check
	$(OBJCOPY) -O ihex $(@:.hex=.out) $@

%.obj: %.c $(EMSOUT)/$(EMSNAME).h
	$(CC) $(CFLAGS) -o $@ $<

$(EMSNAME).obj: $(EMSOUT)/$(EMSNAME).c $(EMSOUT)/$(EMSNAME).h
	$(CC) $(CFLAGS) -o $@ $<

$(EMSOUT)/$(EMSNAME).h: $(SCHEMA)/schema.ems
	$(EMSTOOL) -v --root=$(<D) $<

local-clean:
ifeq (,$(findstring Windows,$(OS)))
	rm -f $(RMFILES)
else
ifneq (,$(wildcard $(RMFILES)))
	cmd /c del /q $(wildcard $(RMFILES))
endif
endif

clean: local-clean
ifeq (,$(findstring Windows,$(OS)))
	rm -rf $(EMSOUT)
else
ifneq (,$(wildcard $(EMSOUT)))
	cmd /c rmdir /q /s $(subst /,\,$(EMSOUT))
endif
endif

out-check:
ifeq (,$(wildcard $(OUTFILE)))
	@echo error: $(OUTFILE): No such file or directory 1>&2
	@exit 1
endif

.PHONY: all load clean local-clean out-check
