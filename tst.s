  .syntax unified
  .cpu cortex-m0
  .fpu softvfp
  .thumb

  .text
  .global tstADD
tstADD:
    adcs r3,r7
    adds r1,r1
    adds r1,r1,20
    adds r1,20
    adds r3,r7,7
    adds r3,1
    adds r1,r2
    adds r1,r1,r2
    add  r1,r9
    add  r1,pc,#20
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
    ands r1,r2
    cpsie i
    cpsid i
    dmb
    dmb  sy
    ldm  r3,  {r3-r7 }
    ldm  r3!, { r1,r2}
    ldr  r3,  [r1,4]
    ldr  r3,  [sp,8]
    ldrb r3,  [r1,#1]
label1:
    mov  r2, r1
    movs r2, r1
    mov  r8, r1
    mrs  r1, iapsr
    movs r2, r1, asr 3
    bl l2
    nop
