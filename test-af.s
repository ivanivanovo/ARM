  .syntax unified
  .cpu cortex-m0
  .fpu softvfp
  .thumb

  .text
  .global tst

tts:
    mov 8,r8 
    adcs R3,r7     
    nop
    adds R1,r1  
l1: adds R1,r1, 20  
    adds R1,20     
    
    adds R3, r7,-7   
    adds R3, 1      
    adds r1, R1, r2  
l2: adds R1, r2     
    add r1, r9      
    add r1, PC, 20   
tt: add PC, r8      
    add r8, PC      
    add SP, SP, SP   
    cmp r1, r2      
    CPSIE i        
    DMB
    B tts 
