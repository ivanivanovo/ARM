\ коммент
hex
\ S" 0100000101mmmddd"  cliche&Mask .bin .bin

Assm: ADDS Rd, Rn, imm         Encod: 0001110iiinnnddd
Assm: AdcS Rd, Rm              Encod: 0100000101mmmddd
Assm: ADDS Rd, imm             Encod: 00110dddiiiiiiii
Assm: ADDS Rd, Rn, Rm          Encod: 0001100mmmnnnddd
' AdcS shwCmd
CR
' adds shwCmd 
\EOF \ локальные отладочные тесты
Assm: ADD  Rdn, Rm             Encod: 01000100dmmmmddd

\ WORDS