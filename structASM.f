The 32-bit instruction begins with:
11101...
11110...
11111...
else 16-bit instruction

ADCS    -> dm               Encod: 0100000101mmmddd
ADD     -> dm  | ddm        Encod: 01000100dmmmmddd
        -> pm  | ppm        Encod: 010001001mmmm111
        -> dsi | ds (i=0)   Encod: 10101dddiiiiiiii
        -> ssi | si         Encod: 101100000iiiiiii

ADDS    -> dni              Encod: 0001110iiinnnddd
        -> di               Encod: 00110dddiiiiiiii
        -> dmn              Encod: 0001100mmmnnnddd

ADR     -> di               Encod: 10100dddiiiiiiii

ASRS    -> dmi              Encod: 00010iiiiimmmddd
        -> dm               Encod: 0100000100mmmddd 

B       -> i!2              Encod: 11100iiiiiiiiiii


LDR     -> tni | tn (i=0)   Encod: 01101iiiiinnnttt                                     Cycles: 2       Action: Rd := [Rn + imm5*4]                             Notes: imm5*4 range 0-124  (word-aligned)
        -> tsi | ts (i=0)   Encod: 10011tttiiiiiiii                                     Cycles: 2       Action: Rd := [SP + imm8*4]                             Notes: imm8*4 range 0-1020 (word-aligned) 
        -> ti               Encod: 01001tttiiiiiiii                                     Cycles: 2       Action: Rt := [PC + imm8*4]                             Notes: imm8*4 range 0-1020 (word-aligned)
        -> tnm              Encod: 0101100mmmnnnttt                                     Cycles: 2       Action: Rd := [Rn + Rm]                                 Notes: 
