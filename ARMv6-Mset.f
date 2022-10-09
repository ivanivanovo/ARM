\ ARMv6-M instructions set 
\ ARM DDI 0419E (ID070218) ARM v6-M Architecture Reference Manual
\ ARM DDI 0432C (ID113009) Cortex -M0 Revision: r0p0 Technical Reference Manual
\ iva 24.03.2021

\ imm   - число 
\ imm!2 - число кратное 2 (чётное)
\ imm!4 - число кратное 4 (дважды чётное)
\ Rdn   - регистр, который можно записать парой одинаковых регистров
\ Rnd   - регистр, который может подменить собой опущеный Rd
\ label - имя, смещение относительно PC, число кратное 2 (чётное)
\ +label - имя, +смещение относительно PC, число кратное 4 (дважды чётное)
\ sjjii - кодирование смещения относительно PC в вид  s:J1:J2:imm10:imm11:0
\ --
\                                                                                  NZCVQ 
\    [    OperandsHandlers      ]
Assm: ADCS Rd, Rm               Encod: 0100000101mmmddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rd + Rm + C-bit                           Notes:  
Assm: ADDS Rdn, imm             Encod: 00110dddiiiiiiii                     Flags: NZCV     Cycles: 1       Action: Rd := Rd + imm8                                 Notes: imm8 range 0-255
Assm: ADDS Rd, Rn, imm          Encod: 0001110iiinnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rn + imm3                                 Notes: imm3 range 0-7
Assm: ADDS Rd, Rnd, Rm          Encod: 0001100mmmnnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rn + Rm                                   Notes: 
Assm: ADD  Rdn, Rm              Encod: 01000100dmmmmddd                                     Cycles: 1       Action: Rd := Rd + Rm                                   Notes: 
Assm: ADD  {PC}, PC, Rm         Encod: 010001001mmmm111                                     Cycles: 3       Action: Pc := PC + Rm                                   Notes: 
Assm: ADD  Rd, SP, imm!4        Encod: 10101dddiiiiiiii                                     Cycles: 1       Action: Rd := SP + imm8*4                               Notes: imm8*4 range 0-1020 (word-aligned)         
Assm: ADD  {SP}, SP, imm!4      Encod: 101100000iiiiiii                                     Cycles: 1       Action: SP := SP + imm7*4                               Notes: imm7*4 range 0-508 (word-aligned)
Assm: ADD  Rd, PC, imm!4        Encod: 10100dddiiiiiiii                                     Cycles: 1       Action: Rd := PC + imm8*4                               Notes: imm8*4 range 0-1020 (word-aligned)
\ Assm: ADR  Rd, +label           Encod: 10100dddiiiiiiii                                     Cycles: 1       Action: Rd := PC + imm8*4                               Notes: imm8*4 range 0-1020 (word-aligned)
Assm: ANDS Rdn, Rm              Encod: 0100000000mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := Rd AND Rm                                 Notes: 
Assm: ASRS Rd,  Rm, imm         Encod: 00010iiiiimmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rm ASR imm5                               Notes: Allowed shifts 1-32
Assm: ASRS Rdn, Rm              Encod: 0100000100mmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rd ASR Rs[7:0]                            Notes: C flag unaffected if Rs[7:0] is 0   
\ Assm: B label                   Encod: 11100iiiiiiiiiii                                     Cycles: 3       Action: PC := label                                     Notes: label=PC + Simm11*2
\ Assm: B{cond} label             Encod: 1101cccciiiiiiii                                     Cycles: 1|3     Action: If {cond} then PC := label                      Notes: label=PC + Simm8*2
Assm: BICS Rdn, Rm              Encod: 0100001110mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := Rd AND NOT Rm                             Notes: 
Assm: BKPT imm                  Encod: 10111110iiiiiiii                                                     Action: BreakPoint                                      Notes:   
\ Assm: BL label                  Encod: 11110sjjjjjjjjjj11a1biiiiiiiiiii  Imcod: sjjii       Cycles: 4       Action: LR := PC+1, PC := label                         Notes: label=PC + Simm24*2
Assm: BLX Rm                    Encod: 010001111mmmm000                                     Cycles: 3       Action: LR := PC - 2 +1, PC := Rm                       Notes: Rm=adr+1
Assm: BX  Rm                    Encod: 010001110mmmm000                                     Cycles: 3       Action: PC := Rm                                        Notes: Rm=adr+1
Assm: CMN Rn, Rm                Encod: 0100001011mmmnnn                     Flags: NZCV     Cycles: 1       Action: APSR flags on Rn + Rm                           Notes:
Assm: CMP Rn, imm               Encod: 00101nnniiiiiiii                     Flags: NZCV     Cycles: 1       Action: APSR flags on Rn - imm                          Notes: imm8 range 0-255
Assm: CMP Rn, Rm                Encod: 0100001010mmmnnn                     Flags: NZCV     Cycles: 1       Action: APSR flags on Rn - Rm                           Notes: Lo to Lo
Assm: CMP Rn, Rm                Encod: 01000101nmmmmnnn                     Flags: NZCV     Cycles: 1       Action: APSR flags on Rn - Rm                           Notes: All to All
Assm: CPSIE i                   Encod: 1011011001100010                                     Cycles: 1       Action: PRIMASK.PM := 0                                 Notes: i -> PRIMASK is affected
Assm: CPSID i                   Encod: 1011011001110010                                     Cycles: 1       Action: PRIMASK.PM := 1                                 Notes: i -> PRIMASK is affected
Assm: DMB                       Encod: 11110011101111111000111101011111                     Cycles: 4                                                               Notes: memory barrier
Assm: DSB                       Encod: 11110011101111111000111101001111                     Cycles: 4                                                               Notes: acts as a special kind of memory barrier
Assm: EORS Rdn, Rm              Encod: 0100000001mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := Rd EOR Rm                                 Notes: 
Assm: ISB                       Encod: 11110011101111111000111101101111                     Cycles: 4                                                               Notes: flushes the pipeline in the processor
\ Assm: LDM Rn{!},<regslist>      Encod: 11001nnnllllllll                                     Cycles: 1+N     Action: R[i] := [Rn+4*i], i=[0-7]                       Notes: loads list of registers
\                                                                                                                                                                     Notes: Rn! { ... } -> Rn not including, after Rn=Rn + 4*N 
\                                                                                                                                                                     Notes: Rn, { .. Rn.. } -> Rn including  
\ Assm: LDMIA -> LDM                                                                                                                                                  Notes: synonym LDM        
\ Assm: LDMFD -> LDM                                                                                                                                                  Notes: synonym LDM        
\ Assm: LDR Rt, [Rn{, imm!4}]     Encod: 01101iiiiinnnttt                                     Cycles: 2       Action: Rd := [Rn + imm5*4]                             Notes: imm5*4 range 0-124  (word-aligned)
\ Assm: LDR Rt, [SP{, imm!4}]     Encod: 10011tttiiiiiiii                                     Cycles: 2       Action: Rd := [SP + imm8*4]                             Notes: imm8*4 range 0-1020 (word-aligned) 
\ Assm: LDR Rt, +label            Encod: 01001tttiiiiiiii                                     Cycles: 2       Action: Rt := [PC + imm8*4]                             Notes: imm8*4 range 0-1020 (word-aligned)
\ Assm: LDR Rt, [Rn, Rm]          Encod: 0101100mmmnnnttt                                     Cycles: 2       Action: Rd := [Rn + Rm]                                 Notes: 
\ Assm: LDRB Rt, [Rn{, imm} ]     Encod: 01111iiiiinnnttt                                     Cycles: 2       Action: Rd := ZeroExtend([Rn + imm5][7:0])              Notes: Clears bits 31:8, imm5 range 0-31
\ Assm: LDRB Rt, [Rn, Rm ]        Encod: 0101110mmmnnnttt                                     Cycles: 2       Action: Rd := ZeroExtend([Rn + Rm][7:0])                Notes: Clears bits 31:8
\ Assm: LDRH Rt, [Rn{, imm} ]     Encod: 10001iiiiinnnttt                                     Cycles: 2       Action: Rd := ZeroExtend([Rn + imm5][15:0])             Notes: Clears bits 31:16, imm5*2 range 0-62 (halfword-aligned)
\ Assm: LDRH Rt, [Rn, Rm ]        Encod: 0101101mmmnnnttt                                     Cycles: 2       Action: Rd := ZeroExtend([Rn + Rm][15:0])               Notes: Clears bits 31:16
\ Assm: LDRSB Rt, [Rn, Rm]        Encod: 0101011mmmnnnttt                                     Cycles: 2       Action: Rd := SignExtend([Rn + Rm][7:0])                Notes: Sets bits 31:8 to bit 7
\ Assm: LDRSH Rt, [Rn, Rm ]       Encod: 0101111mmmnnnttt                                     Cycles: 2       Action: Rd := SignExtend([Rn + Rm][15:0])               Notes: Sets bits 31:16 to bit 15
Assm: LSLS Rd, Rm, imm          Encod: 00000iiiiimmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rm << imm5                                Notes: imm5 range 0-31
Assm: LSLS Rdn, Rm              Encod: 0100000010mmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rd << Rm[7:0]                             Notes: 
Assm: LSRS Rd, Rm, imm          Encod: 00001iiiiimmmddd                     Flags: NZC      Cycles: 1       Action: Rd :==Rm >> imm5                                Notes: imm5 range 0-31
Assm: LSRS Rdn, Rm              Encod: 0100000011mmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rd >> Rm[7:0]                             Notes: 
Assm: MOVS Rd, imm              Encod: 00100dddiiiiiiii                     Flags: NZ       Cycles: 1       Action: Rd := imm8                                      Notes: imm8 range 0-255
Assm: MOV  Rd, Rm               Encod: 01000110dmmmmddd                                     Cycles: 1|3     Action: Rd := Rm                                        Notes: All to All
Assm: MOVS Rd, Rm               Encod: 0000000000mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := Rm                                        Notes: Lo to Lo 
\ Assm: MOVS Rd, Rm, ASR n  -> ASRS Rd, Rm, n                                                                                                                         Notes: synonym ASRS                    
\ Assm: MOVS Rd, Rm, LSL n  -> LSLS Rd, Rm, n                                                                                                                         Notes: synonym LSLS                     
\ Assm: MOVS Rd, Rm, LSR n  -> LSRS Rd, Rm, n                                                                                                                         Notes: synonym LSRS                     
\ Assm: MOVS Rd, Rm, ASR Rs -> ASRS Rd, Rm, Rs                                                                                                                        Notes: synonym ASRS                     
\ Assm: MOVS Rd, Rm, LSL Rs -> LSLS Rd, Rm, Rs                                                                                                                        Notes: synonym LSLS                     
\ Assm: MOVS Rd, Rm, LSR Rs -> LSRS Rd, Rm, Rs                                                                                                                        Notes: synonym LSRS                     
\ Assm: MOVS Rd, Rm, ROR Rs -> RORS Rd, Rm, Rs                                                                                                                        Notes: synonym RORS                     
\ Assm: MRS Rd, spec              Encod: 11110011111011111000ddddssssssss                     Cycles: 4       Action: Rd := spec_reg                                  Notes: 
\ Assm: MSR spec, Rn              Encod: 111100111000nnnn10001000ssssssss                     Cycles: 4       Action: spec_reg := Rn                                  Notes: 
Assm: MULS Rdn, Rn              Encod: 0100001101nnnddd                     Flags: NZ       Cycles: 1-32    Action: Rd := Rn * Rd                                   Notes: 
Assm: MVNS Rd, Rm               Encod: 0100001111mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := NOT Rm                                    Notes: 
Assm: NEGS Rd, Rnd              Encod: 0100001001nnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := -Rn                                       Notes: synonym RSBS Rd, Rn, 0
Assm: NOP                       Encod: 1011111100000000                                     Cycles: 1                                                               Notes:
Assm: ORRS Rdn, Rm              Encod: 0100001100mmmddd                     Flags: NZ       Cycles: 1       Action: Rd := Rd OR Rm                                  Notes: 
\ Assm: POP <regslist>            Encod: 10111100llllllll                                     Cycles: 1+N     Action: R[i] := [SP+4*i], i=[0-7], SP := SP + 4*N       Notes:
\ Assm: POP <regslist+PC>         Encod: 10111101llllllll                                     Cycles: 4+N     Action: POP + branch                                    Notes: branch to address loaded to PC
\ Assm: PUSH <regslist>           Encod: 10110100llllllll                                     Cycles: 1+N     Action: [SP-4*i] := R[i], i=[0-7], SP := SP - 4*N       Notes:
\ Assm: PUSH <regslist+LR>        Encod: 10110101llllllll                                     Cycles: 1+N+1   Action: PUSH + LR                                       Notes:
Assm: REV Rd, Rm                Encod: 1011101000mmmddd                                     Cycles: 1       Action: Rd[31:24] := Rm[7:0], Rd[23:16] := Rm[15:8], Rd[15:8] := Rm[23:16], Rd[7:0] := Rm[31:24]    Notes: reverse bytes in word
Assm: REV16 Rd, Rm              Encod: 1011101001mmmddd                                     Cycles: 1       Action: Rd[31:24] := Rm[23:16], Rd[23:16] := Rm[31:24], Rd[15:8] := Rm[7:0], Rd[7:0] := Rm[15:8]    Notes: reverse bytes in halfwords
Assm: REVSH Rd, Rm              Encod: 1011101011mmmddd                                     Cycles: 1       Action: Rd[31:16] := Rm[7] * &FFFF, Rd[15:8] := Rm[7:0], Rd[7:0] := Rm[15:8] 
Assm: RORS Rdn, Rm              Encod: 0100000111mmmddd                     Flags: NZC      Cycles: 1       Action: Rd := Rd ROR Rs[7:0]                            Notes: 
\ Assm: RSBS Rd, Rm, 0 -> NEGS                                                                                                                                        Notes: synonym NEGS
Assm: SBCS Rdn, Rm              Encod: 0100000110mmmddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rd – Rm – NOT C-bit                       Notes: 
Assm: SEV                       Encod: 1011111101000000                                     Cycles: 1                                                               Notes: Signal event in multiprocessor system
\ Assm: STM Rn!,<regslist>        Encod: 11000nnnllllllll                                     Cycles: 1+N     Action: [Rn-4*i] := R[i], i=[0-7], Rn := Rn - 4*N       Notes:
\ Assm: STMEA -> STM                                                                                                                                                  Notes: synonym STM 
\ Assm: STMIA -> STM                                                                                                                                                  Notes: synonym STM 
\ Assm: STR Rt, [Rn{, imm!4}]     Encod: 01100iiiiinnnttt                                     Cycles: 2       Action: [Rn + imm5*4] := Rt                             Notes: imm5*4 range 0-124  (word-aligned)
\ Assm: STR Rt, [SP{, imm!4}]     Encod: 10010tttiiiiiiii                                     Cycles: 2       Action: [Sp + imm8*4] := Rt                             Notes: imm8*4 range 0-1020 (word-aligned) 
\ Assm: STR Rt, [Rn, Rm]          Encod: 0101000mmmnnnttt                                     Cycles: 2       Action: [Rn + Rm] := Rt                                 Notes: 
\ Assm: STRB Rt, [Rn{, imm}]      Encod: 01110iiiiinnnttt                                     Cycles: 2       Action: [Rn + imm5][7:0] := Rt[7:0]                     Notes: imm5 range 0-31
\ Assm: STRB Rt, [Rn, Rm]         Encod: 0101010mmmnnnttt                                     Cycles: 2       Action: [Rn + Rm][7:0] := Rt[7:0]                       Notes: 
\ Assm: STRH Rt, [Rn{, imm}]      Encod: 10000iiiiinnnttt                                     Cycles: 2       Action: [Rn + imm5*2][15:0] := Rt[15:0]                 Notes: imm5*2 range 0-62 (halfword-aligned) 
\ Assm: STRH Rt, [Rn, Rm]         Encod: 0101001mmmnnnttt                                     Cycles: 2       Action: [Rn + Rm][15:0] := Rt[15:0]                     Notes: 
Assm: SUBS Rd, Rn, imm          Encod: 0001111iiinnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rn – imm3                                 Notes: imm3 range 0-7 
Assm: SUBS Rdn, imm             Encod: 00111dddiiiiiiii                     Flags: NZCV     Cycles: 1       Action: Rd := Rd – imm8                                 Notes: imm8 range 0-255 
Assm: SUBS Rd, Rn, Rm           Encod: 0001101mmmnnnddd                     Flags: NZCV     Cycles: 1       Action: Rd := Rn – Rm                                   Notes: 
Assm: SUB  {SP}, SP, imm!4      Encod: 101100001iiiiiii                                     Cycles: 1       Action: SP := SP – imm7*4                               Notes: imm7*4 range 0-508 (word-aligned)
Assm: SVC imm                   Encod: 11011111iiiiiiii                                     Cycles: -       Action: Send event                                      Notes: 
Assm: SXTB Rd, Rm               Encod: 1011001001mmmddd                                     Cycles: 1       Action: Rd[31:0] := SignExtend(Rm[7:0])                 Notes: 
Assm: SXTH Rd, Rm               Encod: 1011001000mmmddd                                     Cycles: 1       Action: Rd[31:0] := SignExtend(Rm[15:0])                Notes: 
Assm: TST Rn, Rm                Encod: 0100001000mmmnnn                     Flags: NZ       Cycles: 1       Action: APSR flags on Rn AND Rm                         Notes: 
Assm: UDF imm                   Encod: 11011110iiiiiiii                                     Cycles: 1       Action: UNDEFINED                                       Notes: imm8 is for assembly and disassembly only, and is ignored by hardware 
Assm: UDF.W imm                 Encod: 111101111111iiii1010iiiiiiiiiiii                     Cycles: 1       Action: UNDEFINED                                       Notes: imm16 is for assembly and disassembly only, and is ignored by hardware 
Assm: UXTB Rd, Rm               Encod: 1011001011mmmddd                                     Cycles: 1       Action: Rd[31:0] := ZeroExtend(Rm[7:0])                 Notes: 
Assm: UXTH Rd, Rm               Encod: 1011001010mmmddd                                     Cycles: 1       Action: Rd[31:0] := ZeroExtend(Rm[15:0])                Notes: 
Assm: WFE                       Encod: 1011111100100000                                     Cycles: 2       Action: Wait for event, IRQ, FIQ, Imprecise abort, or Debug entry request   Notes: 
Assm: WFI                       Encod: 1011111100110000                                     Cycles: 2       Action: Wait for IRQ, FIQ, Imprecise abort, or Debug entry request          Notes: 
Assm: YIELD                     Encod: 1011111100010000                                     Cycles: 1       Action: Yield control to alternative thread             Notes: 

