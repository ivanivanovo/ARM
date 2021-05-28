\ коммент
\ hex
\ S" 0100000101mmmddd"  cliche&Mask .bin .bin

Assm: AdcS Rd, Rm                 Encod: 0100000101mmmddd
Assm: ADDS Rd, imm                Encod: 00110dddiiiiiiii
Assm: ADDS Rd, Rn, Rm             Encod: 0001100mmmnnnddd
Assm: ADDS Rd, Rn, imm            Encod: 0001110iiinnnddd
Assm: ADD  Rdn, Rm                Encod: 01000100dmmmmddd
Assm: ADD  {PC,} PC, Rm           Encod: 010001001mmmm111
Assm: ADD  Rd, SP, imm!4          Encod: 10101dddiiiiiiii
Assm: ADD  {SP,} SP, imm!4        Encod: 101100000iiiiiii
Assm: ADD  Rd, PC, imm!4          Encod: 10100dddiiiiiiii
\ ' AdcS shwCmd
\ CR
\ ' adds shwCmd 
\ bin[ 101 10111000 disperse . ]bin CR CR
\ bin[ 101 10111000 TUCK disperse SWAP CONDENse . ]bin CR

\ asm? on SP bin> 10111000 <reg> enc @ .bin CR
\ asm? off bin> 10111000 <reg> type CR

 C[ adcs R3 r7 ]C enc @ .HEX CR
 C[ adds R3 r7 1 ]C enc @ .HEX CR
 C[ adds R3 1 ]C enc @ .HEX CR
 C[ adds r0 R0 r1 ]C enc @ .HEX CR
 C[ add r0 r9 ]C enc @ .HEX CR
 C[ add r0 PC 20 ]C enc @ .HEX CR
 C[ add PC r8 ]C enc @ .HEX CR
 C[ add r8 PC ]C enc @ .HEX CR
 C[ add SP SP SP ]C enc @ .HEX CR
\ C[ add r1 PC 11 ]C enc @ .bin CR
\EOF \ локальные отладочные тесты



\ WORDS