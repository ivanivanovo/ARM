\ коммент
hex
\ S" 0100000101mmmddd"  cliche&Mask .bin .bin

Assm: AdcS Rd, Rm              Encod: 0100000101mmmddd
Assm: ADDS Rd, imm             Encod: 00110dddiiiiiiii
Assm: ADDS Rd, Rn, Rm          Encod: 0001100mmmnnnddd
Assm: ADDS Rd, Rn, imm         Encod: 0001110iiinnnddd
Assm: ADD  Rdn, Rm             Encod: 01000100dmmmmddd
\ ' AdcS shwCmd
\ CR
\ ' adds shwCmd 
bin[ 101 10111000 disperse . ]bin CR CR
bin[ 101 10111000 TUCK disperse SWAP CONDENse . ]bin CR

asm? on SP bin> 10111000 <reg> enc @ .bin CR
asm? off bin> 10111000 <reg> type CR

 C[ adcs R3 r7 ]C enc @ .bin CR
 C[ adds R3 r7 1 ]C enc @ .bin CR
 C[ adds R3 1 ]C enc @ .bin CR
 C[ add r9 r10 ]C enc @ .bin CR
\ C[ add r9 r9 r10 ]C enc @ .bin CR

\EOF \ локальные отладочные тесты

\ WORDS