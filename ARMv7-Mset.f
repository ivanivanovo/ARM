\ ARMv7-M instructions set 
\ ARM DDI 0403E.d (ID070218) ARMv7-M Architecture Reference Manual
\ iva 11.04.2021

\ imm   - число
\ imm!2 - число кратное 2 (чётное)
\ imm!4 - число кратное 4 (дважды чётное)
\ label - имя, смещение относительно PC, число кратное 2 (чётное)
\ +label - имя, +смещение относительно PC, число кратное 4 (дважды чётное)
\ label24 - имя, +-смещение относительно PC, очень далекий переход s:J1:J2:imm10:imm11:0
\ --
\                                                                                  NZCVQ 
Assm: ADCS Rd, Rm ;                             Encod: 0100000101mmmddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rd + Rm + C-bit                           Notes:  
Assm: ADC  Rd, Rm ;itb                          Encod: 0100000101mmmddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rd + Rm + C-bit                           Notes:  
Assm: ADC{S} Rd, Rn, imm ;                      Encod: 11110i01010snnnn0iiiddddiiiiiiii     Flags: NZCV     Cycles: 1       Action: Rd := Rd + Rm + imm + C-bit                           Notes:  
Assm: ADC{S} Rd, Rn, Rm{, <shift> } ;           Encod: 11101011010snnnn0iiiddddiittmmmm
ADC{S}<c><q> {<Rd>,} <Rn>, <Rm> {,<shift>}      Encod: 11101011010snnnn0iiiddddiittmmmm