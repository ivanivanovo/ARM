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

l1: C[ adcs R3,r7    ]C \ enc @ .HEX CR  \ 417B 
    C[ adds R1,r1    ]C \ enc @ .HEX CR  \ 1849 
    C[ adds R1,r1,20 ]C \ enc @ .HEX CR  \ 3114 
l2: C[ adds R1,20    ]C \ enc @ .HEX CR  \ 3114 
    C[ adds R3 r7 7  ]C \ enc @ .HEX CR           \ 1DFB 
    C[ adds R3 1     ]C \ enc @ .HEX CR           \ 3301 
    C[ adds r1 R1 r2 ]C \ enc @ .HEX .( <---) CR  \ 1889 <---
    C[ adds R1 r2    ]C \ enc @ .HEX .( <===) CR  \ 1889 <==
    C[ add r1 r9     ]C \ enc @ .HEX CR           \ 4449 
    C[ add r1 PC 20  ]C \ enc @ .HEX CR           \ A105 
    C[ add PC r8     ]C \ enc @ .HEX CR           \ 44C7 
    C[ add r8 PC     ]C \ enc @ .HEX CR           \ 44F8 
    C[ add SP SP SP  ]C \ enc @ .HEX CR           \ 44ED 
    C[ cmp r1 r2     ]C \ enc @ .bin CR           \ 100001010010001
    C[ CPSIE i       ]C \ enc @ .HEX CR           \ B662
    C[ DMB           ]C \ enc @ .UHEX CR          \ F3BF8F5F

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