EMSNAME = Photo

MCU = msp430g2553

CC = msp430-gcc
OBJCOPY = msp430-objcopy
SIZE = msp430-size
MSPDEBUG = mspdebug
MSP430FLASHER = MSP430Flasher
EMSTOOL = emstool

COPTS = -Os -Wall -fno-strict-aliasing -c -g -mmcu=$(MCU)
LDOPTS = -mmcu=$(MCU) -Wl,-Map=main.map

COMMON = ../CommonZeta/eap
SCHEMA = ../../Schema/PhotoSchema
EMSOUT = $(SCHEMA)/out

RMFILES = *.out *.map *.hex *.obj
CFLAGS = -I$(COMMON) -I$(EMSOUT) $(COPTS)
LDFLAGS = $(LDOPTS)
VPATH = $(COMMON)

all: main.out

ifeq (,$(findstring Windows,$(OS)))
load: main.out
	$(MSPDEBUG) rf2500 "prog $<" 2>&1
else
load: main.hex
	$(MSP430FLASHER) -i USB -m AUTO -e ERASE_MAIN -n $(MCU) -w $< -v -z [VCC] -g
endif

main.out: main.obj hal.obj uart.obj timer.obj $(EMSNAME).obj
	$(CC) $(LDFLAGS) -o $@ $^
	$(SIZE) $@

%.hex: %.out
	$(OBJCOPY) -O ihex $< $@

%.obj: %.c $(EMSOUT)/$(EMSNAME).h
	$(CC) $(CFLAGS) -o $@ $<

$(EMSNAME).obj: $(EMSOUT)/$(EMSNAME).c $(EMSOUT)/$(EMSNAME).h
	$(CC) $(CFLAGS) -o $@ $<

$(EMSOUT)/$(EMSNAME).h: $(SCHEMA)/schema.ems
	$(EMSTOOL) -v --root=$(<D) $<

clean:
ifeq (,$(findstring Windows,$(OS)))
	rm -rf $(RMFILES) $(EMSOUT)
else
ifneq (,$(wildcard $(RMFILES)))
	cmd /c del /q $(wildcard $(RMFILES))
endif
endif

.PHONY: all load clean
