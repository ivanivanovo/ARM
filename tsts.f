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
0xFF 0x08000000 0 createSeg: ROM-SEG
ROM-SEG TO SEG

code tts  
        adcs R3,r7     
        adds R1,r1  
    l1: adds R1,r1,20  
        adds R1,20     
        adds R3 r7,7   
        adds R3 1      
        adds r1 R1 r2  
    l2: adds R1 r2     
        add r1 r9      
        add r1 PC 20   
c;
code tt add PC r8      
        add r8 PC      
        add SP SP SP   
        cmp r1 r2      
        CPSIE i        
        DMB 
c;
hex[ 
 c[ B tts ]C             
]hex

helpasm cmp
CR 
\ ' ADD shwCmd
' DMB shwCmd

SEG SEGdump CR
\ 91AB9A4   7B 41 49 18  14 31 14 31  FB 1D 01 33  89 18 89 18 {AI..1.1�..3�.�.
\ 91AB9B4   49 44 05 A1  C7 44 F8 44  ED 44 91 42  62 B6 5F 8F ID.��D�D�D�Bb�_�
\ 91AB9C4   BF F3 00 00  00 00 00 00  00 00 00 00  00 00 00 00 ��..............
' l2 shwLabel CR
\ WORDS