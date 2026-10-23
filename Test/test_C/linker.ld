ENTRY(_start)

MEMORY
{
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 8K
  RAM (rw) : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
  /* 代码段：运行在 ROM */
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > ROM

  /* 只读数据段：运行地址和存储地址都在 ROM */
  .rodata : {
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
  } > ROM

  /* 已初始化数据：运行地址在 RAM，初始内容存放在 ROM */
  .data : ALIGN(4) {
    _data_start = .;
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
    . = ALIGN(4);
    _data_end = .;
  } > RAM AT> ROM

  _data_lma = LOADADDR(.data);

  /* 未初始化数据：仅占用 RAM，启动时清零 */
  .bss : ALIGN(4) {
    _bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}