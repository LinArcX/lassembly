.set IRQ_BASE, 0x20
.section .text
.extern _ZN17InterruptsManager15handleInterruptEhj
.global _ZN17InterruptsManager22IgnoreInterruptRequestEv

.macro HandleException num
.global _ZN17InterruptsManager16HandleException\num\()Ev
_ZN17InterruptsManager16HandleException\num\()Ev:
  movb $\num, (interruptNumber)
  jmp int_bottom
.endm

.macro HandleInterruptRequest num
.global _ZN17InterruptsManager26HandleInterruptRequest\num\()Ev
_ZN17InterruptsManager26HandleInterruptRequest\num\()Ev:
  movb $\num + IRQ_BASE, (interruptNumber)
  jmp int_bottom
.endm

HandleInterruptRequest 0x00
HandleInterruptRequest 0x01

int_bottom:
  pusha
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs

  push %esp
  push (interruptNumber)
  call _ZN17InterruptsManager15handleInterruptEhj
  # addl $5, %esp
  mov %eax, %esp

  popl %gs
  popl %fs
  popl %es
  popl %ds
  popa

_ZN17InterruptsManager22IgnoreInterruptRequestEv:
  iret

.data
  interruptNumber: .byte 0
