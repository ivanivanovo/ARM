\ язык для описания команд ассемблера
\ 
\ Condition number
\    cond                Mnemonic  Meaning                         Condition flags
BIN> 0000 CONSTANT   ..EQ    \ EQual                           Z == 1
BIN> 0001 CONSTANT   ..NE    \ Not Qqual                       Z == 0
BIN> 0010 CONSTANT   ..CS    \ Carry Set                       C == 1
BIN> 0010 CONSTANT   ..HS    \ unsigned Higher or Same         C == 1
BIN> 0011 CONSTANT   ..CC    \ Carry Clear                     C == 0
BIN> 0011 CONSTANT   ..LO    \ unsigned LOwer                  C == 0
BIN> 0100 CONSTANT   ..MI    \ MInus, negative                 N == 1
BIN> 0101 CONSTANT   ..PL    \ PLus, positive or zero          N == 0
BIN> 0110 CONSTANT   ..VS    \ oVerflow Set                    V == 1
BIN> 0111 CONSTANT   ..VC    \ oVerflow Clear                  V == 0
BIN> 1000 CONSTANT   ..HI    \ unsigned HIgher                 C == 1 and Z == 0
BIN> 1001 CONSTANT   ..LS    \ unsigned Lower or Same          C == 0 or Z == 1
BIN> 1010 CONSTANT   ..GE    \ signed Greater than or Equal    N == V
BIN> 1011 CONSTANT   ..LT    \ signed Less Than                N != V
BIN> 1100 CONSTANT   ..GT    \ signed Greater Than             Z == 0 and N == V
BIN> 1101 CONSTANT   ..LE    \ signed Less than or Equal       Z == 1 or N != V
BIN> 1110 CONSTANT   ..AL    \ ALways (unconditional) Any

0
CELL -- .Rd   \ destinantion register number
CELL -- .Rn   \ base register number, first operand register number
CELL -- .Rm   \ midle register number, second operand number
CELL -- .Rt   \ target register number
CELL -- .imm  \ immediate value
CELL -- .cond \ conditions of passage
CELL -- .Set  \ seting flags
CONSTANT fields_of_mnemonic

CREATE pre fields_of_mnemonic ALLOT 

: wash ( --) \ смывка предварительных полей
    -1 pre .Rd   !
    -1 pre .Rn   !
    -1 pre .Rm   !
    -1 pre .Rt   !
     0 pre .imm  !
  ..AL pre .cond !
 FALSE pre .Set  !
     ;




REQUIRE NewChain chain.f
NewChain asmChain
: Assm: ( .mem> --) \ начинает цепочку связанных полей для описания 
    \ ассемблерной команда .mem  
    BL PARSE ( adr u)
    DUP IF asmChain inject ELSE 2DROP THEN
    ;