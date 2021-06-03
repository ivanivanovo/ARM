\ коммент
\ hex
\ S" 0100000101mmmddd"  cliche&Mask .bin .bin

Assm: ADCS Rd, Rm               Encod: 0100000101mmmddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rd + Rm + C-bit                           Notes:  
Assm: ADDS Rd, Rn, imm          Encod: 0001110iiinnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rn + imm3                                 Notes: imm3 range 0-7
Assm: ADDS Rdn, imm             Encod: 00110dddiiiiiiii                     Flags: NZCV     Cycles: 1       Action: Rd := Rd + imm8                                 Notes: imm8 range 0-255
Assm: ADDS Rd, Rn, Rm           Encod: 0001100mmmnnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rn + Rm                                   Notes: 
Assm: ADD  Rdn, Rm              Encod: 01000100dmmmmddd                                     Cycles: 1       Action: Rd := Rd + Rm                                   Notes: 
Assm: ADD  {PC,} PC, Rm         Encod: 010001001mmmm111                                     Cycles: 3       Action: Pc := PC + Rm                                   Notes: 
Assm: ADD  Rd, SP, imm!4        Encod: 10101dddiiiiiiii                                     Cycles: 1       Action: Rd := SP + imm8*4                               Notes: imm8*4 range 0-1020 (word-aligned)         
Assm: ADD  {SP,} SP, imm!4      Encod: 101100000iiiiiii                                     Cycles: 1       Action: SP := SP + imm7*4                               Notes: imm7*4 range 0-508 (word-aligned)
Assm: ADD  Rd, PC, imm!4        Encod: 10100dddiiiiiiii                                     Cycles: 1       Action: Rd := PC + imm8*4                               Notes: imm8*4 range 0-1020 (word-aligned)
\ Assm: ADR  Rd, +label           Encod: 10100dddiiiiiiii                                     Cycles: 1       Action: Rd := PC + imm8*4                               Notes: imm8*4 range 0-1020 (word-aligned)
Assm: ANDS Rdn, Rm              Encod: 0100000000mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := Rd AND Rm                                 Notes: 
Assm: ASRS Rd,  Rm, imm         Encod: 00010iiiiimmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rm ASR imm5                               Notes: Allowed shifts 1-32
Assm: ASRS Rdn, Rm              Encod: 0100000100mmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rd ASR Rs[7:0]                            Notes: C flag unaffected if Rs[7:0] is 0   
\ EOF
\ ' AdcS shwCmd
\ CR
\ ' adds shwCmd 
\ bin[ 101 10111000 disperse . ]bin CR CR
\ bin[ 101 10111000 TUCK disperse SWAP CONDENse . ]bin CR

\ asm? on SP bin> 10111000 <reg> enc @ .bin CR
\ asm? off bin> 10111000 <reg> type CR

 C[ adcs R3 r7 ]C enc @ .HEX CR
 C[ adds R1 r1 ]C enc @ .HEX CR
 C[ adds R1 r1 2 ]C enc @ .HEX CR
 C[ adds R1 2 ]C enc @ .HEX CR
 C[ adds R3 r7 1 ]C enc @ .HEX CR
 C[ adds R3 1 ]C enc @ .HEX CR
 C[ adds r1 R1 r2 ]C enc @ .HEX .( <---) CR
 C[ adds R1 r2 ]C enc @ .HEX .( <==) CR
 C[ add r1 r9 ]C enc @ .HEX CR
 C[ add r1 PC 20 ]C enc @ .HEX CR
 C[ add PC r8 ]C enc @ .HEX CR
 C[ add r8 PC ]C enc @ .HEX CR
 C[ add SP SP SP ]C enc @ .HEX CR
\ C[ add r1 PC 11 ]C enc @ .bin CR
\EOF \ локальные отладочные тесты



\ WORDS