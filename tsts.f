\ коммент
\ hex
\ ' AdcS shwCmd
\ CR
\ ' adds shwCmd 
\ bin[ 101 10111000 disperse . ]bin CR CR
\ bin[ 101 10111000 TUCK disperse SWAP CONDENse . ]bin CR

\ asm? on SP bin> 10111000 <reg> enc @ .bin CR
\ asm? off bin> 10111000 <reg> type CR

 C[ adcs R3 r7 ]C enc @ .HEX CR
 C[ adds R1 r1 ]C enc @ .HEX CR
 C[ adds R1 r1 20 ]C enc @ .HEX CR
 C[ adds R1 20 ]C enc @ .HEX CR
 C[ adds R3 r7 7 ]C enc @ .HEX CR
 C[ adds R3 1 ]C enc @ .HEX CR
 C[ adds r1 R1 r2 ]C enc @ .HEX .( <---) CR
 C[ adds R1 r2 ]C enc @ .HEX .( <==) CR
 C[ add r1 r9 ]C enc @ .HEX CR
 C[ add r1 PC 20 ]C enc @ .HEX CR
 C[ add PC r8 ]C enc @ .HEX CR
 C[ add r8 PC ]C enc @ .HEX CR
 C[ add SP SP SP ]C enc @ .HEX CR
 C[ cmp r1 r2 ]C enc @ .bin CR
helpasm cmp
\EOF \ локальные отладочные тесты



\ WORDS