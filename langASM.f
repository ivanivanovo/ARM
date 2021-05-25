\ язык для описания команд ассемблера
\ 
REQUIRE toolbox  toolbox.f
REQUIRE CASE   lib/ext/case.f
REQUIRE 2CONSTANT lib/include/double.f
DECIMAL \ десятичная система счисления
VOCABULARY ASSEMBLER
ALSO ASSEMBLER DEFINITIONS

300 COUNTER: ErrNo
ErrNo CONSTANT errNoReg     \ Не регистр
ErrNo CONSTANT errRlo       \ Не младший регистр
ErrNo CONSTANT errRdn       \ Разные регистры
ErrNo CONSTANT errBigOp     \ Слишком большое число в операнде 
ErrNo CONSTANT errImm!2     \ нечетное число 
ErrNo CONSTANT errImm!4     \ невыровненное число
ErrNo CONSTANT err+Label    \ метка должна быть только вперед

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
\ в стековой нотации эта пара [r,x]
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


VARIABLE ASM? \ переменная состояния, TRUE кодирование, FALSE декодирование 
ASM? ON 
\ : ASM> POSTPONE ASM? POSTPONE @  POSTPONE IF ; IMMEDIATE 
\ : DIS> POSTPONE EXIT POSTPONE THEN ; IMMEDIATE
#def ASM> ASM? @ IF
#def DIS> EXIT THEN
#def R<<  R> 1 LSHIFT >R

: disperse ( u mask -- u') \ рассыпать биты числа u по маске
    0 -ROT 1 >R
    BEGIN ( _u _mask) OVER \ пока_u>0
    WHILE DUP \ пока _mask>0 
        WHILE DUP 1 AND IF -ROT TUCK 1 AND IF R@ + THEN SWAP 1 RSHIFT  ROT THEN 
              1 RSHIFT  R<<  
    REPEAT
        errBigOp THROW \ u слишком большое, не помещается в маску
    THEN  2DROP R> DROP
    ;

: condense ( u' mask -- u) \ собрать число u из u' по битовой маске
    0 -ROT 1 >R
    BEGIN DUP \ пока маска>0
    WHILE DUP 1 AND IF -ROT TUCK 1 AND IF R@ + THEN SWAP R<< ROT THEN
          1 RSHIFT SWAP 1 RSHIFT SWAP  
    REPEAT 2DROP R> DROP
    ;

: Reg! ( [r,x] encode --) \ запомнить номер регистра в структуре pre
    ROT itisReg = IF ! ELSE errNoReg THROW THEN
    ;

: Reg# ( #Reg -- c-adr u) \ дать строку с цифровым именем регистра
    S>D DEC[ <# #S [CHAR] R HOLD #> ]DEC 
    ;

: RegName ( #Reg -- c-adr u) \ дать строку с именем регистра
    DUP 13 = IF DROP S" SP" ELSE
    DUP 14 = IF DROP S" LR" ELSE
    DUP 15 = IF DROP S" PC" ELSE
    Reg# \ неименованый регистр будет с номером
    THEN THEN THEN
    ;
    
: <Reg>  \ обработчик регистров
    ASM> ( [r,x] encode -- ) Reg! 
    DIS> ( encode -- c-adr u ) @ RegName
    ;

: <Imm> \ простое числовое значение
    ASM> ( x adr --) !
    DIS> ( adr -- x) @
    ; 

: inStr? ( x adr u -- f) \ x есть в строке adr u?
    ROT FALSE 2SWAP OVER + SWAP
    DO ( x f ) OVER I C@ = IF DROP TRUE LEAVE THEN
    LOOP NIP
    ;
\ ----обработчик------ |--тэг--|--операнд-----|-синоним|
:NONAME pre .Rd  <Reg> ; CHAR d 2CONSTANT Rd  : Rd, Rd ;
:NONAME pre .Rn  <Reg> ; CHAR n 2CONSTANT Rn  : Rn, Rn ;
:NONAME pre .Rm  <Reg> ; CHAR m 2CONSTANT Rm  : Rm, Rm ;
:NONAME pre .Rt  <Reg> ; CHAR t 2CONSTANT Rt  : Rt, Rt ;
:NONAME pre .imm <Imm> ; CHAR i 2CONSTANT imm
:NONAME ( {[r,x]} [r,x] --) 
    2>R OVER itisReg =
    IF \ два регистра
        2R@ D= 0= errRdn AND THROW \ проверка убивает дубликат
    THEN \ один регистр
    2R> pre .Rd  <Reg> ; CHAR d 2CONSTANT Rdn  : Rdn, Rdn ;

VARIABLE encodes 0 encodes ! \ кончик цепочки енкодов
: asmcoder ( adr-alt -- ) 
    \ BEGIN @ \ перебор альтернатив 
    \ WHILE 
    \ REPEAT
    ;
: discoder ( )
    ;

\ структура мнемоники
\ alt   - указатель на вариант операндов/енкода для ассемблирования
\ c-str - мнемоника, строка со счетчиком

: Assm: ( "mnemonics" -- ->mnemo ) \ создает или находит структуру 
    \ ассемблерной команды <mnemonics>
    \ возвращает ссылку на неё
    >IN @  BL PARSE 2>R \ R: adr u - мнемоника во входном буфере
    2R@ UPPERCASE-W \ ВСЕГДА В ВЕРХНЕМ РЕГИСТРЕ
    2R@ GET-CURRENT SEARCH-WORDLIST  
    IF  \  есть такое, 
        NIP  2R> 2DROP
        >BODY \ выдать адрес структуры мнемоники
    ELSE \ нету, создать
        >IN ! CREATE    
        HERE 0 , 2R> str!
        ALIGN 
        DOES> asmcoder
    THEN 
    ;

: +net ( adr net -- adr') \ включить adr в цепочку net
    \ adr' указатель на следующее звено
    DUP @ -ROT ! 
    ;

: tagMask ( adr u tag -- маска) \ из стоки adr u вида "0100000101mmmddd"
    \ сделать маску по тэгу(символу)
    \ маска - число у которого биты =1 
    \ в позициях, где тэг/символ встречается в строке
    \      0100000101mmmddd 
    \ d -> 0000000000000111
    \ m -> 0000000000111000
    \ 0 -> 1011111010000000
    \ 1 -> 0100000101000000
    0 2SWAP
    OVER + SWAP
    DO ( tag mask) 2* OVER I C@ = IF 1+ THEN
    LOOP NIP
    ;

: cliche&mask ( adr u -- маска клише) \ из стоки adr u вида "0100000101mmmddd"
    \ сделать клише и маску команды
    \ по маске из машинного слова выделяется опознавательный код команды,
    \ а клише служит для сравнения "код=клише"
    2DUP 
    [CHAR] 1 tagMask >R \ mask1=клише
    [CHAR] 0 tagMask R@ ( mask0 mask1)
    OR \ маска01
    R> 
    ;

0 \ структура операнда
CELL -- .tag
CELL -- .maskOp
CELL -- .xtOp
CONSTANT structOp

0 \ структура кодировщика команды
CELL -- .link     \  поле связи цепи всех кодировщиков
CELL -- .alt      \  поле связи цепи альтернатив
CELL -- .cliche   \  клише команды
CELL -- .mask     \  маска команды
structOp -- .ops  \  операнд
\  ...            \  другие операнды
\ CELL - 0        \  тэг мнемоники или конец операндов
\ CELL - adrMnemo \  адрес структуры мнемоники
DROP

: structEncode ( mnem n*[xt,teg] adr u2 -- mnem) \ создать структуру кодировщика команды
    \ по шаблону adr u2
    2>R
    2R@ cliche&mask , ,
    BEGIN DUP 2R@ inStr? \ потребление операндов
    WHILE DUP , 2R@ ROT tagMask , , REPEAT
    2R> 2DROP
    0 , DUP , 
    ;
    
: Encod: ( mnem n*[xt,teg] "encode" --  ) \ строит структуру кодирования 
\ потребляет операнды и мнемонику со стека
    HERE encodes +net , \ включиться в цепочку кодировщиков
    0 , \ указатель на альтернативный кодировщик
    BL PARSE structEncode
    BEGIN DUP @ WHILE @ CELL+ REPEAT encodes @ SWAP !
    ;








\ ============================================================================
\ слова лишние, но помогающие
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

#def tab> R@ SPACES
: 32bit. ( u -- ) \ печатать 32-битное число в бинаронм виде
    8 CELLS BIN[ U.0R ]BIN 
    ;
: shwEncode ( adr tab --) \ показать структуру кодировщика команды
    \ с отступом tab
    >R 
    tab> ." =======================================" CR 
    tab> DUP       ." link=  " @ .HEX                CR 
    tab> DUP .alt  ." alt=   " @ .HEX                CR 
    tab> ." ---------------------------------------" CR 
    tab> DUP .cliche ." clishe=" @ 32bit.            CR 
    tab> DUP .mask   ." mask=  " @ 32bit.            CR 
         .ops
         BEGIN DUP  @ WHILE
    tab>     DUP   ." tag=   " @ EMIT                CR 
    tab>     DUP .maskOp ." mask=  " @ 32bit.        CR 
    tab>     DUP .xtOp   ." xt=    " @ .HEX          CR 
             structOp +
         REPEAT
    tab> CELL+ @ CELL+ ." mnemo= " COUNT TYPE        CR 
    R> DROP
    ;

: shwMnemo ( xt --) \ показать структуру мнемоники
    >BODY
    DUP @ ." alt=   " .HEX CR
    CELL+ ." mnemo= " COUNT TYPE CR
    ;

: shwCmd ( xt --) \ показать команду полностью
    DUP shwMnemo
    >BODY 0 >R
    BEGIN DUP @ 
    WHILE @ DUP R> 4 + DUP >R shwEncode CELL+ 
    REPEAT DROP R> DROP
    ;

\ PREVIOUS DEFINITIONS    
#def langASM .( loaded) CR


