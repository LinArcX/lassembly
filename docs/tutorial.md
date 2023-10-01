# information

# tips
- pardis will be start in 32bit mode
  - so it means that we compile .asm, .cpp .ld files in 32bit mode.

# structure of pardis os
we have two main parts:

## loader.s
this file that is located in src/asm/loader.s will pass to `as` and it will generate: `loader.o`
  when using grub as bootloader, it needs to boot our os. so we should tell him how he should do it.
  in loader.s we put MAGIC number to tell bootloader the final .iso file is an actual os.
  and after that we called kernelMain routine.(that is defined in src/cpp/kernel.cpp)
  and then we reserverd 2 Mib of size for loader.

### magic number
if you tell the computer to treat an .iso file as an operating system, your bootloader won't beleive you,
  unless you put some magic number at the beginning of your .iso file: 0x1badb002

### checksum
bootloaders may want to try different operating systems. to distinguish one from others, they need to be sure, each of os are unique.


## kernel.cpp
this file that is located in src/cpp/kernel.cpp will pass to `g++` and it will generate: `kernel.o`
  This is the entry point of our os. we have a kernelMain() function, and we pass it two arguments from loader.s:
  - multiboot_structure
  - magic_number
  and then we used our own implementation of pirntf() to print something on screen.(since we're os right now, we don't have printf() from glibc)
  for make our os unique, we put a checksum in .multiboot section in our loader file.

### write on the screen by graphic card directly
There is a specific memory location on ram with this address: 0xb8000
and whatever you write here, will be put on the screen by the graphics card.

we used this technique to write on screen in pardis, since when pardis loads, there is no printf() from stdlib.
```
void printf(const char* str)
{
  uint16_t* VideoMemory = (uint16_t*)0xb8000;
  for(int32_t i = 0; str[i] != '\0'; i++)
  {
    VideoMemory[i] = (VideoMemory[i] & 0x2200) | str[i];
  }
}
```

As you can see, we defined uint16_t or short(2 bytes) for VideoMemory location. why? becuase every character has 2 bytes:
1. first byte reserved for coloring(4 high bits for background and 4 low bits for foreground colors)
2. second byte reserved for actuall charachter.

0xb8000:
       -------------
       | a| b| c| d|
       -------------

## linker.ld
this file will merge two other object files(loader.o and kernel.o) that were generated in previous steps and will generate a .bin file.
then we use xorriso tool to generate .iso file from this .bin file. we can burn this .iso file and start using it in qemu or installing it on bare-bone hardware:)

in linker.ld we select .sections from different .o files and combine them together.
