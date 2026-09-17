# RISC-V toolchain
CROSS := riscv64-unknown-elf-

CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy

# CPU configuration
ARCH := rv32i
ABI  := ilp32

# Linker script
LDSCRIPT := linker.ld

# Common GCC options
CFLAGS := \
	-march=$(ARCH) \
	-mabi=$(ABI) \
	-nostdlib \
	-nostartfiles \
	-T $(LDSCRIPT)

# All assembly source files
SRCS := $(wildcard *.S)

# Generate corresponding ELF / HEX files
ELFS := $(SRCS:.S=.elf)
HEXS := $(SRCS:.S=.hex)

.PHONY: all clean

all: $(HEXS)

# .S -> .elf
%.elf: %.S $(LDSCRIPT)
	$(CC) $(CFLAGS) $< -o $@

# .elf -> .hex
%.hex: %.elf
	$(OBJCOPY) \
		-O verilog \
		--verilog-data-width 4 \
		$< $@

clean:
	rm -f *.elf *.hex
