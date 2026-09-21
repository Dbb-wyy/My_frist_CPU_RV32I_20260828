ENTRY(_start)

MEMORY
{
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 8K
  RAM (rw) : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > ROM

  .rodata : {
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
  } > ROM

  /* VMA = RAM，LMA = ROM（紧接 .rodata 之后） */
  .data : {
    _data_start = .;
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
    _data_end = .;
  } > RAM AT> ROM

  _data_lma = LOADADDR(.data);

  .bss : {
    _bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
    *(COMMON)
    _bss_end = .;
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
