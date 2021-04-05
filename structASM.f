The 32-bit instruction begins with:
11101...
11110...
11111...
else 16-bit instruction

ADD     -> RR  | R=RR       Encod: 01000100dmmmmddd
        -> PR  | PPR        Encod: 010001001mmmm111
        -> RSI | RS(I=0)    Encod: 10101dddiiiiiiii
        -> SSI | SI         Encod: 101100000iiiiiii

ADDS    -> RRI              Encod: 0001110iiinnnddd
        -> RI               Encod: 00110dddiiiiiiii
        -> RRR              Encod: 0001100mmmnnnddd

LDR     -> RRI | RR(I=0)    Encod: 01101iiiiinnnttt                                     Cycles: 2       Action: Rd := [Rn + imm5*4]                             Notes: imm5*4 range 0-124  (word-aligned)
        -> RSI | RS(I=0)    Encod: 10011tttiiiiiiii                                     Cycles: 2       Action: Rd := [SP + imm8*4]                             Notes: imm8*4 range 0-1020 (word-aligned) 
        -> RA               Encod: 01001tttiiiiiiii                                     Cycles: 2       Action: Rt := [PC + imm8*4]                             Notes: imm8*4 range 0-1020 (word-aligned)
        -> RRR              Encod: 0101100mmmnnnttt                                     Cycles: 2       Action: Rd := [Rn + Rm]                                 Notes: 
