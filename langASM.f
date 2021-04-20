\ язык для описания команд ассемблера
\ 
REQUIRE toolbox  toolbox.f
DECIMAL \ десятичная система счисления
VOCABULARY ASSEMBLER
ALSO ASSEMBLER DEFINITIONS

300 COUNTER: ErrNo
ErrNo CONSTANT errRlo
ErrNo CONSTANT errImm!2
ErrNo CONSTANT errImm!4
ErrNo CONSTANT err+Label

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

\ Регистр представлен на стеке парой чисел:
\ признак регистра & номер регистра
129 CONSTANT itisReg \ признак регистра
: REGISTER: ( n <name> --) \ слово определяющее регистр
    CREATE , itisReg , 
    DOES> 2@ 
    ;
 0 REGISTER: R0     1 REGISTER: R1     2 REGISTER: R2      3 REGISTER: R3
 4 REGISTER: R4     5 REGISTER: R5     6 REGISTER: R6      7 REGISTER: R7
 8 REGISTER: R8     9 REGISTER: R9    10 REGISTER: R10    11 REGISTER: R11
12 REGISTER: R12   13 REGISTER: R13   14 REGISTER: R14    15 REGISTER: R15
                   13 REGISTER: SP    14 REGISTER: LR     15 REGISTER: PC

0
CELL -- .next       \ указатель на следующий член списка
CELL -- .operands   \ указатель на поле операндов
   1 -- .mnemo      \ строка со счетчиком, мнемоника
CONSTANT mnemonics_struct

VARIABLE Mnemonics  \ кончик списка мнемоник
0 Mnemonics ! \ список пуст

: search_Mnemo ( adr u -- link) \ искать такую же мнемонику
    \ если нет, то вернуть 0
    2>R
    Mnemonics @
    BEGIN DUP 
    WHILE DUP .mnemo COUNT 2R@ COMPARE
    WHILE @ REPEAT 
    THEN
    2R> 2DROP
    ;

: addMnemonics ( adr u -- link) \ 
    Mnemonics @ HERE Mnemonics ! , 0 , str! 
    ALIGN
    Mnemonics @
    ;

: Assm: ( <mnemonics> -- link) \ начинает цепочку связанных полей для описания 
    \ ассемблерной команда <mnemonics>
    >IN @  BL PARSE 2>R \ adr u - мнемоника 
           2R@ UPPERCASE-W \ ВСЕГДА В ВЕРХНЕМ РЕГИСТРЕ
           2R@ search_Mnemo
    DUP 0= 
    IF DROP >IN ! CREATE \ нету, создать
       2R@ addMnemonics  \ добавить в цепь
    ELSE NIP THEN
    2R> 2DROP
    ;


\ PREVIOUS DEFINITIONS    
#def langASM .( loaded) CR

Assm: a1
\ EOF
Assm: b1
Assm: a2
Assm: b1
