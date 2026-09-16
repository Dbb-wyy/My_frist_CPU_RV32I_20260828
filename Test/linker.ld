ENTRY(_start)

MEMORY
{
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 8K
  RAM (rw) : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
  .text : {
    *(.text)
    *(.text.*)
  } > ROM

  .rodata : {
    *(.rodata)
    *(.rodata.*)
  } > ROM

  .data : {
    *(.data)
    *(.data.*)
  } > RAM

  .bss : {
    *(.bss)
    *(.bss.*)
    *(COMMON)
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
