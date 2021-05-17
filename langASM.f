\ язык для описания команд ассемблера
\ 
REQUIRE toolbox  toolbox.f
DECIMAL \ десятичная система счисления
VOCABULARY ASSEMBLER
ALSO ASSEMBLER DEFINITIONS

300 COUNTER: ErrNo
ErrNo CONSTANT errNoReg
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

: shwPRE ( --) \ показать предварительные поля
    ." ------------------------------------" CR
    ." |cond| S | Rd | Rt | Rn | Rm | imm |" CR
    ." ------------------------------------" CR
    pre .cond @ 4 .R 2 SPACES
    pre .Set  @ 2 .R SPACE   
    pre .Rd   @ 4 .R SPACE
    pre .Rt   @ 4 .R SPACE
    pre .Rn   @ 4 .R SPACE
    pre .Rm   @ 4 .R SPACE
    pre .imm  @ 4 .R SPACE
    CR 
    ." ------------------------------------" CR
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



\ структура мнемоники
\ next   - указатель на цепь операндов для ассемблирования
\ prev   - 0
\ c-str  - мнемоника, строка со счетчиком

: ascoder  ;

: mnemo. ( c-str --) \ выдать мнемонику команды
    COUNT TYPE
    ;
: decoder ( opN .. op2 op1 c-str --) 
    mnemo.
    @ DROP \ переход к следующему     
    ;

: Assm: ( "mnemonics" -- aop> ) \ создает или находит структуру 
    \ ассемблерной команды <mnemonics>
    \ возвращает ссылку на неё
    >IN @  BL PARSE 2>R \ R: adr u - мнемоника во входном буфере
    2R@ UPPERCASE-W \ ВСЕГДА В ВЕРХНЕМ РЕГИСТРЕ
    2R@ GET-CURRENT SEARCH-WORDLIST  
    IF  >BODY  
        NIP  2R> 2DROP
    ELSE \ нету, создать
        >IN ! CREATE    
        HERE 0 , 0 , 2R> str!
        ALIGN 
        DOES> ascoder
    THEN 
    ;


\ PREVIOUS DEFINITIONS    
#def langASM .( loaded) CR


Assm: AdcS \  Rd, Rm            \  Encod: 0100000101mmmddd
\EOF \ локальные отладочные тесты
Assm: ADDS Rd, Rn, imm        \  Encod: 0001110iiinnnddd
Assm: ADDS Rd, imm            \  Encod: 00110dddiiiiiiii
Assm: ADDS Rd, Rn, Rm         \  Encod: 0001100mmmnnnddd
Assm: ADD  Rdn, Rm            \  Encod: 01000100dmmmmddd

WORDS