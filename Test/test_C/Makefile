CROSS   := riscv64-unknown-elf-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy

ARCH := rv32i
ABI  := ilp32

# 目录配置
CODE_DIR := code
ELF_DIR  := ELFS
HEX_DIR  := HEXS

LDSCRIPT := linker.ld
START    := start.S

# C 编译与链接选项
CFLAGS := \
	-march=$(ARCH) -mabi=$(ABI) \
	-nostdlib \
	-nostartfiles \
	-ffreestanding \
	-fno-builtin \
	-fno-common \
	-O0 -Wall \
	-T $(LDSCRIPT)

# GCC runtime library
LIBGCC := -lgcc

# 自动扫描源码
TESTS_C := $(wildcard $(CODE_DIR)/test_*.c)
TESTS_S := $(wildcard $(CODE_DIR)/test_*.S)

# 将 code/test_x.c 映射到 ELFS/test_x.elf
ELFS := $(patsubst $(CODE_DIR)/%.c,$(ELF_DIR)/%.elf,$(TESTS_C)) \
        $(patsubst $(CODE_DIR)/%.S,$(ELF_DIR)/%.elf,$(TESTS_S))

# 将 ELFS/test_x.elf 映射到 HEXS/test_x.hex
HEXS := $(patsubst $(ELF_DIR)/%.elf,$(HEX_DIR)/%.hex,$(ELFS))

.PHONY: all clean dirs

all: $(HEXS) $(ELFS)

# 确保输出目录存在
dirs:
	mkdir -p $(ELF_DIR) $(HEX_DIR)

# C 测试：start.S + code/test_x.c
$(ELF_DIR)/%.elf: $(CODE_DIR)/%.c $(START) $(LDSCRIPT) | dirs
	$(CC) $(CFLAGS) $(START) $< $(LIBGCC) -o $@

# 纯汇编测试：code/test_x.S
$(ELF_DIR)/%.elf: $(CODE_DIR)/%.S $(LDSCRIPT) | dirs
	$(CC) $(CFLAGS) $< -o $@

# ELF 转换为 Verilog HEX
$(HEX_DIR)/%.hex: $(ELF_DIR)/%.elf | dirs
	$(OBJCOPY) -O verilog --verilog-data-width 4 $< $@

clean:
	rm -f $(ELF_DIR)/*.elf $(HEX_DIR)/*.hex
