\ язык для описания команд ассемблера
\ 
REQUIRE toolbox         toolbox.f
REQUIRE 2CONSTANT       lib/include/double.f
REQUIRE +net            nets.f
REQUIRE err:            errorsnet.f
REQUIRE enqueueNOTFOUND nf-ext.f

#def NOT 0= ( x --T|F) \ инверсия результата
    \ усли x=0 - FALSE, иначе TRUE

DECIMAL \ десятичная система счисления
VOCABULARY ASSEMBLER
ALSO ASSEMBLER DEFINITIONS

VARIABLE ASM? \ переменная состояния, TRUE кодирование, FALSE декодирование 
VARIABLE operator 0 operator ! \ текущий оператор (команда)
VARIABLE lastDepth \ глубина стека перед отсрочкой оператора
VARIABLE lastErrAsm \ код последней ошибки ассемблера
VARIABLE enc \ текущий код команды
VARIABLE encodes 0 encodes ! \ кончик цепочки енкодов

: replaceBytes ( adr u b1 b2 -- adr u i) \ заменить в строке adr u все быйты b1 на b2
    \ i -количество замен
    2>R 2DUP 0 -ROT 2R> 2SWAP 
    OVER + SWAP
    DO OVER I C@ = IF DUP I C! ROT 1+ -ROT THEN
    LOOP 2DROP 
    ;

: nf-commaFree ( adr u -- true | adr u false) 
\ попробовать интерпретировать строку без запятых
    [CHAR] , BL replaceBytes
    IF EVALUATE TRUE ELSE FALSE THEN 
    ;
' nf-commaFree enqueueNOTFOUND

300 COUNTER: ErrNo
ErrNo err: errEncode S" не удалось закодировать"
ErrNo err: errNoReg  S" Не регистр"
ErrNo err: errRlo    S" Не младший регистр"
ErrNo err: errRdn    S" Разные регистры"
ErrNo err: errBigOp  S" Слишком большое число в операнде"
ErrNo err: errOddOp  S" лишнее операнды или их нехватка"
ErrNo err: errImm!2  S" нечетное число "
ErrNo err: errImm!4  S" невыровненное число"
ErrNo err: err+Label S" метка должна быть только вперед"

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


\ Регистр представлен на стеке парой чисел:
\ признак регистра & номер регистра
\ в стековой нотации эта пара обозначается [r,x]
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



ASM? ON 
\ : ASM> POSTPONE ASM? POSTPONE @  POSTPONE IF ; IMMEDIATE 
\ : DIS> POSTPONE EXIT POSTPONE THEN ; IMMEDIATE

#def ASM> ASM? @ IF
#def DIS> EXIT THEN
#def R<<  R> 1 LSHIFT >R

: 2RSHIFT ( x1 x2 u -- x1>>u x2>>u) \ сдвинуть вправо пару чисел
    DUP >R RSHIFT SWAP R> RSHIFT SWAP 
    ;

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
          1 2RSHIFT   
    REPEAT 2DROP R> DROP
    ;


: >enc ( x mask --) \ вложить x в текущий код команды
    disperse enc @ OR enc !
    ;  
: enc> ( mask -- x) \ вытащить число из текущей команды
    enc @ SWAP condense
    ;

\ ============ Обработка операндов ==================================

: itisReg? ( r x -- r x f) \ TRUE - регистр
    DEPTH 1 > 
    IF OVER itisReg = 
    ELSE FALSE THEN
    ;

: Reg! ( [r,x] mask --) \ запомнить номер регистра в текущей команде
    >R itisReg? IF NIP R> >enc ELSE errNoReg THROW THEN
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
    ASM> ( [r,x] mask -- ) Reg! 
    DIS> ( mask -- c-adr u ) enc> RegName
    ;

: <Imm> \ простое числовое значение
    ASM> ( x mask --) >enc 
    DIS> ( mask -- x) enc>
    ; 

: inStr? ( x adr u -- f) \ x есть в строке adr u?
    ROT FALSE 2SWAP OVER + SWAP
    DO ( x f ) OVER I C@ = IF DROP TRUE LEAVE THEN
    LOOP NIP
    ;

: maybe_duplex ( {[r,x]} [r,x] -- [r,x]) \ опциональный дубль регистров
    \ если на стеке два регистра, то они должны быть одинаковые
    \ дубль убрать
    2>R itisReg?
    IF 2R@ D= NOT errRdn AND THROW \ проверка убивает дубликат
    THEN \ один регистр
    2R>
    ;
: need_two ( {[r',x']} [r,x] -- [r',x'] [r,x]) \ нужно два регистра
    \ если на стеке два регистра - ничего не делать
    \ если на стеке один регистр - продублировать его
    2>R itisReg? NOT IF 2R@ THEN 2R>
    ;

: assert= ( [r,x] [r,x] --) D= NOT errEncode AND THROW 
    ;


\ ############ Обработчики операндов ###########################

\ обработчик|-тэг-|--операнд-----|-синоним|
' <Reg>     CHAR d 2CONSTANT Rd  \ : Rd, Rd ;
' <Reg>     CHAR n 2CONSTANT Rn  \ : Rn, Rn ;
' <Reg>     CHAR m 2CONSTANT Rm  \ : Rm, Rm ;
' <Reg>     CHAR t 2CONSTANT Rt  \ : Rt, Rt ;
' <Imm>     CHAR i 2CONSTANT imm
:NONAME ( {[r',x']} [r,x] mask -- [r',x']) >R need_two R> <Reg> ;
    \ в отсутствии Rd ([r',x']), Rn ([r,x]) оставит свой дубликат ([r,x]=[r',x'])
            CHAR n 2CONSTANT Rnd \ : Rnd, Rnd ;  \  
:NONAME ( {[r,x]} [r,x] mask --) >R maybe_duplex R> <Reg> ; 
            CHAR d 2CONSTANT Rdn  \ : Rdn, Rdn ;
:NONAME (  PC mask --)   DROP PC assert= ;
            CHAR c 2CONSTANT PC  
:NONAME ( {PC,} mask --) DROP itisReg? IF PC assert= THEN ;
            CHAR * 2CONSTANT {PC}
:NONAME (  SP mask --)   DROP SP assert= ;
            CHAR p 2CONSTANT SP  
:NONAME ( {SP,} mask --) DROP itisReg? IF SP assert= THEN ;
            CHAR * 2CONSTANT {SP} 
:NONAME ( imm!4 mask --) 
    >R DUP 3 AND IF errImm!4 THROW ELSE 4 / THEN R> <Imm> ;
            CHAR i 2CONSTANT imm!4
:NONAME ( imm!2 mask --) 
    >R DUP 1 AND IF errImm!2 THROW ELSE 2/  THEN R> <Imm> ;
            CHAR i 2CONSTANT imm!2

\ ===================================================================

: +listExcepTag ( adr u -- adr' u') \ добавить к строке тэги исключения
    \ строка adr u не изменяется, изменяется её временная копия
    >S S" cp*" +>S S> ; 

0 \ структура операнда
CELL -- .tag
CELL -- .maskOp
CELL -- .xtOp
CONSTANT structOp

0 \ структура кодировщика команды
CELL -- .link     \  поле связи цепи всех кодировщиков
CELL -- .alt      \  поле связи цепи альтернатив
CELL -- .help     \  помощники команды
CELL -- .cliche   \  клише команды
CELL -- .mask     \  маска команды
structOp -- .ops  \  операнд
\  ...            \  другие операнды
\ CELL - 0        \  тэг мнемоники или конец операндов
\ CELL - adrMnemo \  адрес структуры мнемоники
\    x - phrase   \  фраза команды  
DROP

: execOp ( j*x adr-ops -- i*x) \ выполнить обработчики операндов
    BEGIN  DUP @
    WHILE  DUP >R .maskOp 2@ SWAP EXECUTE R> structOp +
    REPEAT DROP
    ; 
: sacker ( j*x adr-alt --) \ упаковать операнды в код
    DUP .cliche @ enc !
    .ops execOp
    \ проверить потребление операндов
    DEPTH lastDepth @ - IF errOddOp THROW THEN
    ;

\ ============ стек временного хранения стека данных ================
100 VSTACK T \ V-стек 
: nDROP ( j*x u -- [j-n]*x) \ множественное удаление данных со стека
    >R DEPTH R> MIN
    ?DUP IF 0 DO DROP LOOP THEN
    ;
\ : NDROP ( i*x i -- )
\   CELLS SP@ CELL+ + SP!
\ ;


: T! DEPTH T >STACK ; \ запомнит стек на всю глубину
: T@ DEPTH T @ @ MIN nDROP \ очистить стек под восстановление
     T STACK@ DROP \ востановить данне стека
     ;
: Tdrop T STACK>DROP ; \ убрать запись восстановления 
\ ===================================================================
\ TODO: сделать накопитель ошибок
\ если все альтернативы дали сбой - выдать весь список
\ если хоть одна сработала - забыть про них
: errQuit ( --)
    0 operator ! 
    SOURCE TYPE CR 
    >IN @ 2- SPACES ." ^-" lastErrAsm @ err? TYPE 
    QUIT \ THROW
    ; 

: asmcoder ( j*x adr-alt -- i*x ) 
    \ на стеке лежат операнды предыдущего оператора/команды
    \ заменить оператор на предыдущий,
    operator @ SWAP operator ! \ а текущий будет ждать своих операндов
    ?DUP 
    IF @ T! \ сделать снимок стека
        \ цикл перебора альтернативных кодировок
        BEGIN T@ \ восстановить стек
            ['] sacker CATCH ?DUP \ попытка кодирования 
        WHILE lastErrAsm ! \ неудача
              \ восстановить стек после сбоя
              T@ .alt @ ?DUP \ перейти на альтернативную кодировку
        WHILE Tdrop T! \ сделать новый снимок стека
        REPEAT Tdrop errQuit \ выход с ошибкой
        THEN
        Tdrop \ нормальный выход, сброс снимка 
    THEN
    DEPTH lastDepth ! \ запомнить текущую глубину стека
    ;

: c[ ( --) \ начать ассемблирование
    ASM? ON \ переключить режим
    ;
: ]c ( --) \ закончить ассемблирование
    0 asmcoder \ обработать последний операнд
    ASM? OFF \ переключить режим
    ;    

: discoder ( )
    ;

S"     " DROP @ CONSTANT 4BL \ 4 пробела как число 
: phrase ( <str> -- adr u)  \ выделить из входного потока фразу
    \ фраза: последовательность слов разделенных не более чем 3 пробелами
    SOURCE >IN @ /STRING SWAP >R \ R: адрес начала строки
    0 \ u i
    BEGIN  2DUP = NOT WHILE DUP R@ + @ 4BL = NOT WHILE 1+ REPEAT THEN
    NIP R> SWAP
    ;

: 4BLparse ( <str> -- adr u) \ взять из входного потока фразу
    \ фраза: последовательность слов разделенных не более чем 3 пробелами
    phrase >IN @ OVER + >IN ! \ отрезать фразу
    ;

\ структура мнемоники
\ alt   - указатель на вариант операндов/енкода для ассемблирования
\ c-str - мнемоника, строка со счетчиком

: Assm: ( "mnemonics" -- -> adr u mnemo ) \ создает или находит структуру 
    \ ассемблерной команды <mnemonics>
    \ возвращает ссылку на неё
    \ и её фразу
    phrase
    >IN @  BL PARSE 2>R \ R: adr u - мнемоника во входном буфере
    2R@ UPPERCASE-W \ ВСЕГДА В ВЕРХНЕМ РЕГИСТРЕ
    2R@ GET-CURRENT SEARCH-WORDLIST  
    IF  \  есть такое, 
        NIP  2R> 2DROP
        >BODY \ выдать адрес структуры мнемоники
    ELSE \ нету, создать
        >IN ! CREATE    
        HERE 0 , 2R> str! ALIGN 
        DOES> asmcoder
    THEN 
    ;


: tagMask ( adr u tag -- маска) \ из строки adr u вида "0100000101mmmddd"
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

: cliche&mask ( adr u -- маска клише) \ из строки adr u вида "0100000101mmmddd"
    \ сделать клише и маску команды
    \ по маске из машинного слова выделяется опознавательный код команды,
    \ а клише служит для сравнения "код=клише"
    2DUP 
    [CHAR] 1 tagMask >R \ mask1=клише
    [CHAR] 0 tagMask R@ ( mask0 mask1)
    OR \ маска01
    R> 
    ;

: netHelp+ ( -- ) \ добавить Это место к помощникам
    HERE encodes @ .help net+ 
    ;

: structEncode ( adr u mnem n*[xt,teg] adr2 u2 -- mnem) \ создать структуру кодировщика команды
    \ по шаблону adr2 u2
    2>R
    2R@ cliche&mask , ,
    BEGIN DUP 2R@ +listExcepTag inStr? 
        \ потребление операндов
    WHILE DUP , 2R@ ROT tagMask , , REPEAT
    2R> 2DROP
    0 , DUP , -ROT 
    netHelp+ 0 , [CHAR] P , str! ALIGN \ запомнить фразу команды
    ;
    
: Encod: ( mnem n*[xt,teg] "encode" --  ) \ строит структуру кодирования 
\ потребляет операнды и мнемонику со стека
    HERE 0 , encodes +net \ включиться в цепочку кодировщиков (в начало)
    0 , \ указатель на альтернативный кодировщик
    0 , \ помощники
    BL PARSE structEncode \ создать структуру
    \ и включить ее в конец цепочки альтернатив
    BEGIN DUP @ WHILE @ CELL+ REPEAT encodes @ SWAP !
    ;


\ ============== слова помощники/описатели команд ===========================

0 \ структура помощника
CELL -- .hLink \ связь
CELL -- .hTag  \ метка
   1 -- .hStr  \ строка описания
DROP \ переменный размер

: helper: ( tag <name> -- ) \ определить помощника
    CREATE ,
    DOES> @ netHelp+ 0 , , 4BLparse str! ALIGN 
    ;

CHAR A helper: Action: ( <str> --) \ строка описывающее действие команды
CHAR F helper: Flags:  ( <str> --) \ -*- флаги на которые влияет команда
CHAR C helper: Cycles: ( <str> --) \ -*- циклы
CHAR N helper: Notes:  ( <str> --) \ дополнительные замечания

: tag. ( symbol --) \ развернуть тэг
    DUP [CHAR] P = IF ." Phrase: " ELSE
    DUP [CHAR] A = IF ." Action: " ELSE
    DUP [CHAR] F = IF ." Flags : " ELSE
    DUP [CHAR] C = IF ." Cycles: " ELSE
    DUP [CHAR] N = IF ." Notes : " 
    THEN THEN THEN THEN THEN DROP
    ;

#def tab> R@ SPACES
: help. ( .help tab --)
    >R
    BEGIN @ DUP 
    WHILE DUP .hTag C@ tab> tag.
          DUP .hStr COUNT TYPE CR
    REPEAT DROP 
    R> DROP
    ;

: helpAsm ( <name> --) \ показать справку по команде <name>
    CR BL WORD FIND
    IF  >BODY ( xt)
        0 >R
        BEGIN @ DUP 
        WHILE DUP .help R@ help. .alt 
              R> 4 + >R
        REPEAT DROP 
        R> DROP
    ELSE DROP
    THEN
    ;

\ ============================================================================
\ слова лишние, но помогающие

: 32bit. ( u -- ) \ печатать 32-битное число в бинарном виде
    8 CELLS BIN[ U.0R ]BIN 
    ;
: shwEncode ( adr tab --) \ показать структуру кодировщика команды
    \ с отступом tab
    >R 
    tab> ." =======================================" CR 
    tab> DUP       ." link=  " @ .HEX                CR 
    tab> DUP .alt  ." alt=   " @ .HEX                CR 
    tab> DUP .help ." hlp=   " @ .HEX                CR 
    tab> ." ---------------------------------------" CR 
    tab> DUP .cliche ." clishe=" @ 32bit.            CR 
    tab> DUP .mask   ." mask=  " @ 32bit.            CR 
         DUP .ops
         BEGIN DUP  @ WHILE
    tab>     DUP   ." tag=   " @ EMIT                CR 
    tab>     DUP .maskOp ." mask=  " @ 32bit.        CR 
    tab>     DUP .xtOp   ." xt=    " @ .HEX          CR 
             structOp +
         REPEAT
    tab> CELL+ @ CELL+ ." mnemo= " COUNT TYPE        CR
    tab> ." ---------------------------------------" CR 
    .help R@ help.  CR 
    R> DROP
    ;

: shwMnemo ( xt --) \ показать структуру мнемоники
    >BODY
    DUP @ ." alt=   " .HEX CR
    CELL+ ." mnemo= " COUNT TYPE CR
    ;

: shwCmd ( xt --) \ показать команду полностью
    DUP shwMnemo
    >BODY 0 SWAP ( tab xt)
    BEGIN @ DUP 
    WHILE SWAP 4 + 2DUP shwEncode SWAP .alt 
    REPEAT 2DROP 
    ; \ пример импользования: ' ANDS shwCmd
\ PREVIOUS DEFINITIONS    
#def langASM .( loaded) CR


