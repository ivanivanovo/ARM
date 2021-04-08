  .syntax unified
  .cpu cortex-m0
  .fpu softvfp
  .thumb

  .text
  .global tstADD
tstADD:
    adds r0,r1,r2
    adds r0,r0,r7
    adds r0,r1
    add  r0,r9
    add  r0,pc,#20
    ADD  PC , R8
    add  r8,pc
    add  sp,sp,sp
    //adr  r0, label1
    beq  l2
    bl   l2
    b .
l2: bl   label1
    cmp  r1,r9
    cmp  r1,r2
    ands r0,r1
    cpsie i
    cpsid i
    dmb
    dmb  sy
    ldm  r0,  {r0-r7 }
    ldm  r0!, { r1,r2}
    ldr  r0,  [r1,4]
    ldr  r0,  [sp,8]
    ldrb r0,  [r1,#1]
label1:
    mov  r0, r1
    movs r0, r1
    mov  r8, r1
    mrs  r1, iapsr
    movs r0, r1, asr 3
    bl l2
    nop
