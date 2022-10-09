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
CURSTR @ . C[ adcs R3 r7 ]C enc @ .HEX CR          \ 417B 
CURSTR @ . C[ adds R1 r1 ]C enc @ .HEX CR         \ 1849 
CURSTR @ . C[ adds R1 r1 20 ]C enc @ .HEX CR      \ 3114 
CURSTR @ . C[ adds R1 20 ]C enc @ .HEX CR         \ 3114 
CURSTR @ . C[ adds R3 r7 7 ]C enc @ .HEX CR       \ 1DFB 
CURSTR @ . C[ adds R3 1 ]C enc @ .HEX CR          \ 3301 
CURSTR @ . C[ adds r1 R1 r2 ]C enc @ .HEX .( <---) CR \ 1889 <---
CURSTR @ . C[ adds R1 r2 ]C enc @ .HEX .( <==) CR \ 1889 <==
CURSTR @ . C[ add r1 r9 ]C enc @ .HEX CR          \ 4449 
CURSTR @ . C[ add r1 PC 20 ]C enc @ .HEX CR       \ A105 
CURSTR @ . C[ add PC r8 ]C enc @ .HEX CR          \ 44C7 
CURSTR @ . C[ add r8 PC ]C enc @ .HEX CR          \ 44F8 
CURSTR @ . C[ add SP SP SP ]C enc @ .HEX CR       \ 44ED 
CURSTR @ . C[ cmp r1 r2 ]C enc @ .bin CR          \ 100001010010001
CURSTR @ . C[ CPSIE i ]C enc @ .HEX CR            \ B662
CURSTR @ . C[ DMB ]C enc @ .UHEX CR               \ F3BF8F5F
helpasm cmp
CR 
\ ' ADD shwCmd
' DMB shwCmd
.( ================================) CR \


\ WORDS