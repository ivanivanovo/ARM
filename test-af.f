\ коммент
\ hex
\ ' AdcS shwCmd
\ CR
\ ' adds shwCmd 
\ bin[ 101 10111000 disperse . ]bin CR CR
\ bin[ 101 10111000 TUCK disperse SWAP CONDENse . ]bin CR

\ asm? on SP bin> 10111000 <reg> enc @ .bin CR
\ asm? off bin> 10111000 <reg> type CR

\ EOF \ локальные отладочные тесты
0x08000000 0 1024 createSeg: ROM-SEG
ROM-SEG TO SEG

: delArg BL WORD DROP ; \  сожрать аргумент
\ .syntax unified
: .syntax delArg ;
\ .cpu cortex-m0
: .cpu delArg ; \ cortex-m0
\ .fpu softvfp
: .fpu delArg ; \ softvfp
: .thumb ; \
: .text  ROM-SEG TO SEG ;
\ .global tst
: .global delArg ; \ tst

#def nop  mov r8,r8 \ чтоб совпадал с arm-none-eabi-as
\ C[ test-af.s ]C
C[   
tts:
    nop
    mov r8,r8
    adcs R3,r7     
    adds R1,r1  
l1: adds R1,r1,20  
    adds R1,20     
    adds R3, r7,7   
    adds R3, 1      
    adds r1, R1, r2  
l2: adds R1, r2     
    add r1, r9      
    add r1, PC, 20   
tt: add PC, r8      
    add r8, PC      
    add SP, SP, SP   
    cmp r1, r2      
\    CPSIE i        
\    DMB
\    B tts 

]C

SEG SEGdump CR

' DMB shwCmd
\ hex
\ errChain chPrint
\ errList.
\ dbg on
\ CR errRlo err? TYPE