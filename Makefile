##### Directories #####
BUILD_DIR     := build
ASSETS_DIRS   := assets
ASM_DIRS      := $(shell find asm -path "asm/data" -prune -o -path "asm/nonmatchings" -prune -o -type d -print)
ASM_DATA_DIRS := $(shell find asm/data -type d)
SRC_DIRS      := $(shell find src/ -type d)

##### Files #####
TARGET     := gga
LD_SCRIPT  := $(TARGET).ld
SPLAT_YAML := $(TARGET).yaml

C_FILES        := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
S_FILES        := $(foreach dir,$(ASM_DIRS),$(wildcard $(dir)/*.s))
S_DATA_FILES   := $(foreach dir,$(ASM_DATA_DIRS),$(wildcard $(dir)/*.data.s))
S_RODATA_FILES := $(foreach dir,$(ASM_DATA_DIRS),$(wildcard $(dir)/*.rodata.s))
ASSET_FILES    := $(foreach dir,$(ASSETS_DIRS),$(wildcard $(dir)/*.bin))

O_FILES := $(foreach file,$(C_FILES),$(BUILD_DIR)/$(file:.c=.c.o)) \
           $(foreach file,$(S_FILES),$(BUILD_DIR)/$(file:.s=.s.o)) \
           $(foreach file,$(S_DATA_FILES),$(BUILD_DIR)/$(file:.data.s=.data.s.o)) \
           $(foreach file,$(S_RODATA_FILES),$(BUILD_DIR)/$(file:.rodata.s=.rodata.s.o)) \
           $(foreach file,$(DATA_FILES),$(BUILD_DIR)/$(file:.bin=.bin.o)) \

##### Tools #####
ifeq ($(shell type mips-n64-ld >/dev/null 2>/dev/null; echo $$?), 0)
  CROSS := mips-n64-
else ifeq ($(shell type mips-linux-gnu-ld >/dev/null 2>/dev/null; echo $$?), 0)
  CROSS := mips-linux-gnu-
else ifeq ($(shell type mips64-linux-gnu-ld >/dev/null 2>/dev/null; echo $$?), 0)
  CROSS := mips64-linux-gnu-
else
  CROSS := mips64-elf-
endif

AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJDUMP := $(CROSS)objdump
OBJCOPY := $(CROSS)objcopy

CC := tools/ido/linux/5.3/cc1
# CC := tools/ido/linux/7.1/cc1

SPLAT := python3 tools/splat/split.py

##### Options #####
OPTFLAGS := -O2

DEFINE_CFLAGS  := -D_LANGUAGE_C -D_FINALROM -DF3DEX_GBI_2 -D_MIPS_SZLONG=32
INCLUDE_CFLAGS := -I . -I include
CFLAGS         := -G0 -mips2 -non_shared -fullwarn -verbose -Xcpluscomm -Wab,-r4300_mul $(DEFINE_FLAGS) $(INCLUDE_CFLAGS)
ASFLAGS        := -EB -mtune=vr4300 -march=vr4300 -I include

OBJDUMP_FLAGS := -d -r -z -Mreg-names=32

GCC_CFLAGS := -Wall $(DEFINE_CFLAGS) $(INCLUDE_CFLAGS) -fno-PIC -fno-zero-initialized-in-bss -fno-toplevel-reorder -Wno-missing-braces -Wno-unknown-pragmas
CC_CHECK := gcc -fsyntax-only -fno-builtin -nostdinc -fsigned-char -m32 $(GCC_CFLAGS) -std=gnu90 -Wall -Wextra -Wno-format-security -Wno-main -DNON_MATCHING -DAVOID_UB

##### Targets #####
build/src/%.o: CC := python3 tools/asm_processor/build.py $(CC) -- $(AS) $(ASFLAGS) --
build/asm/%.o: ASFLAGS += -mips3 -mabi=32

default: all

all: $(BUILD_DIR) $(BUILD_DIR)/$(TARGET).z64 verify

distclean: asmclean assetclean clean

clean:
	rm -rf $(BUILD_DIR)

asmclean:
	rm -rf asm
	rm -f $(LD_SCRIPT)

assetclean:
	rm -rf assets

split: $(SPLAT_YAML)
	$(SPLAT) $<

setup:
	clean split

$(BUILD_DIR): $(LD_SCRIPT)
	$(shell mkdir -p build/baserom $(foreach dir,$(SRC_DIRS) $(ASM_DIRS) $(ASM_DATA_DIRS) $(ASSETS_DIRS),build/$(dir)))

$(BUILD_DIR)/%.c.o: %.c
	@$(CC_CHECK) -MMD -MP -MT $@ -MF $(BUILD_DIR)/$*.d $<
	$(CC) -c $(CFLAGS) $(OPTFLAGS) -o $@ $^
	$(OBJDUMP) $(OBJDUMP_FLAGS) $@ > $(@:.o=.s)

$(BUILD_DIR)/%.s.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/%.bin.o: %.bin
	$(LD) -r -b binary -o $@ $<

$(LD_SCRIPT): $(SPLAT_YAML)
	rm -f $@
	$(SPLAT) $<

$(BUILD_DIR)/$(LD_SCRIPT): $(LD_SCRIPT)
	@mkdir -p $(@D)
	cpp -P -o $@ $<

$(BUILD_DIR)/$(TARGET).elf: $(BUILD_DIR)/$(LD_SCRIPT) $(O_FILES)
	$(LD) -T undefined_funcs_auto.txt -T undefined_syms_auto.txt -T $(BUILD_DIR)/$(LD_SCRIPT) -Map $(BUILD_DIR)/$(TARGET).map --no-check-sections -o $@

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) $< $@ -O binary

$(BUILD_DIR)/$(TARGET).z64: $(BUILD_DIR)/$(TARGET).bin
	@cp $< $@

verify: $(BUILD_DIR)/$(TARGET).z64
	md5sum -c checksum.md5