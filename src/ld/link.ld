# This is a linker script that:
# 1. sets the entry point of the os.
# 2. specifies the output format and architecture,
# 3. and defines sections for text, data, and BSS, and discards certain sections from final .bin file.
# It provides instructions to the linker on how to combine the object files and generate the final binary file.

# specifies the entry point of the program, which is set to the symbol boot. When the program starts executing, it will begin execution from the boot symbol.
ENTRY(boot)

OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386:i386)

SECTIONS
{
  # sets the current address (.) to the hexadecimal value 0x0100000. It establishes the base address for subsequent sections.
  . = 0x0100000;

  # This section defines the .text section, which typically contains executable instructions.
  .text :
  {
    *(.multiboot)
    *(.text*)
    *(.rodata)
  }

  # This section defines the .data section, which typically contains initialized data.
  .data :
  {
    # start_ctors and end_stors are used to mark the start and end of the constructors' array, which is used for initializing global objects.
    start_ctors = .;
    KEEP(*( .init_array ));
    KEEP(*( SORT_BY_INIT_PRIORITY( .init_array.* ) ))
    end_ctors = .;

    *(.data)
  }

  # This section defines the .bss section, which typically contains uninitialized (zero-initialized) data.
  .bss :
  {
    *(.bss)
  }

  # This section specifies the contents that should be discarded and not included in the output file.
  /DISCARD/ :
  {
    # This directive discards the contents of the .fini_array section, which contains function pointers to destructors.
    *(.fini_array*)
    *(.comment)
  }
}
