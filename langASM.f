\ язык для описания команд ассемблера
\ 
REQUIRE toolbox         toolbox.f
REQUIRE 2CONSTANT       lib/include/double.f
REQUIRE +chain          chains.f
REQUIRE err:            errorschain.f
REQUIRE enqueueNOTFOUND nf-ext.f
REQUIRE alloc           heap.f

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
chain: encodes \ кончик цепочки енкодов

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
ErrNo err: errNoSym  S" неверный символ-аргумент"

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

\ : <label> \ метка
\     ASM> ( adr mask -- adr-PC) SWAP enc - SWAP >enc
\     DIS> ( mask -- c-adr u ) enc> LabelName
\     ;

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

\ структура мнемоники
0
CELL -- .mAlt \ ->указатель на вариант операндов/енкода для ассемблирования
CELL -- .mStr \ ->указатель на мнемонику, строку со счетчиком
CONSTANT structMnem 

0 \ структура операнда
CELL -- .oLnk       \ поле связи цепи всех операндов
CELL -- .oTag       \ метка операнда
CELL -- .oMask      \ макска операнда    
CELL -- .oXt        \ обработчик операнда
CONSTANT structOp

0 \ структура кодировщика варианта команды
CELL -- .eLnk       \ поле связи цепи всех кодировщиков
CELL -- .eAlt       \ поле связи цепи альтернатив
CELL -- .eHlp       \ ->цепочка, помощники команды
CELL -- .eCliche    \ клише команды
CELL -- .eMask      \ маска команды
CELL -- .eXt        \ токен предварительного исполнения
CELL -- .eMnemo     \ адрес структуры мнемоники
CELL -- .eOps       \ ->цепь операндов
CONSTANT structEncode

0 \ структура помощника
CELL -- .hLink \ связь
CELL -- .hTag  \ метка
CELL -- .hStr  \ ->строка описания
CONSTANT structHelper



MODULE: OperandsHandlers
\ ############ Обработчики операндов ###########################

\ обработчик|-тэг-|--операнд-----|-синоним|
' <Reg>     CHAR d 2CONSTANT Rd  
' <Reg>     CHAR n 2CONSTANT Rn  
' <Reg>     CHAR m 2CONSTANT Rm  
' <Reg>     CHAR t 2CONSTANT Rt  
' <Imm>     CHAR i 2CONSTANT imm
:NONAME ( {[r',x']} [r,x] mask -- [r',x']) >R need_two R> <Reg> ;
    \ в отсутствии Rd ([r',x']), Rn ([r,x]) оставит свой дубликат ([r,x]=[r',x'])
            CHAR n 2CONSTANT Rnd   
:NONAME ( {[r,x]} [r,x] mask --) >R maybe_duplex R> <Reg> ; 
            CHAR d 2CONSTANT Rdn  \ : Rdn, Rdn ;
:NONAME ( {PC,} mask --) DROP itisReg? IF PC assert= THEN ;
            CHAR * 2CONSTANT {PC}
:NONAME (  PC mask --)   DROP PC assert= ;
            CHAR c 2CONSTANT PC  
:NONAME ( {SP,} mask --) DROP itisReg? IF SP assert= THEN ;
            CHAR * 2CONSTANT {SP} 
:NONAME (  SP mask --)   DROP SP assert= ;
            CHAR p 2CONSTANT SP  
:NONAME ( imm!4 mask --) 
    >R DUP 3 AND IF errImm!4 THROW ELSE 4 / THEN R> <Imm> ;
            CHAR i 2CONSTANT imm!4
:NONAME ( imm!2 mask --) 
    >R DUP 1 AND IF errImm!2 THROW ELSE 2/  THEN R> <Imm> ;
            CHAR i 2CONSTANT imm!2
: <I> ( <c> --) \ проверка символа "i"
    BL WORD COUNT DROP C@ CHAR-UPPERCASE [CHAR] I = NOT IF errNoSym THROW THEN ;
: i ( --)
    ['] <I> encodes @ .eXt ! ;
;MODULE
\ ===================================================================

: +listExcepTag ( adr u -- adr' u') \ добавить к строке тэги исключения
    \ строка adr u не изменяется, изменяется её временная копия
    >S S" cp*" +>S S> ; 

: execOp ( j*x adr-ops -- i*x) \ выполнить обработчики операндов
    BEGIN  @ DUP 
    WHILE  >R
           R@ .oMask @ 
           R@ .oXt @ EXECUTE 
           R> .oLnk
    REPEAT DROP
    ; 
: sacker ( j*x adr-alt --) \ упаковать операнды в код
    DUP .eCliche @ enc !
    .eOps execOp
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
    DUP \ не 0
    IF \ предисполнитель
        DUP @ .eXt @ EXECUTE
    THEN
    \ заменить оператор на предыдущий,
    operator @ SWAP operator ! \ а текущий будет ждать своих операндов
    ?DUP 
    IF @ T! \ сделать снимок стека
        \ цикл перебора альтернативных кодировок
        BEGIN T@ \ восстановить стек
            ['] sacker CATCH ?DUP \ попытка кодирования 
        WHILE lastErrAsm ! \ неудача
              \ восстановить стек после сбоя
              T@ .eAlt @ ?DUP \ перейти на альтернативную кодировку
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

: 4BLparse ( <str> -- adr u) \ изъять из входного потока фразу
    \ фраза: последовательность слов разделенных не более чем 3 пробелами
    phrase >IN @ OVER + >IN ! \ отрезать фразу
    ;

: createMnemo ( adr u -- adr_strMnemo)
    2DUP CREATED    
    structMnem alloc
    DUP .mAlt iniChain 
    -ROT str> OVER .mStr ! 
    DUP ,
    DOES> @ asmcoder
    ;

: createEncode ( -- adr_strEncode) \ создать структуру кодировщика
    structEncode alloc   \ обнулить поля структуры
    DUP .eLnk  encodes +chain   \ включиться в цепочку кодировщиков (в начало)
    DUP .eAlt  iniChain
    DUP .eHlp  iniChain
    DUP .eOps  iniChain
    ;
    
: createHlp ( tag adr u -- adr_strHlp) \ создать структуру помощника
    str> \ tag c-addr
    structHelper alloc  ( tag c-adr adr_Hlp)  \ обнулить поля структуры
    TUCK .hStr !
    TUCK .hTag !
    ;

: Assm: ( <mnemonics> -- -> ) \ создает или находит структуру 
    \ ассемблерной команды <mnemonics>
    \ возвращает ссылку на неё
    [CHAR] P phrase -BL createHlp \ hlp запомнить фразу команды в структуре помощника
    BL WORD COUNT    \ hlp adr u - мнемоника во входном буфере
    2DUP UPPERCASE-W \ ВСЕГДА В ВЕРХНЕМ РЕГИСТРЕ
    2DUP GET-CURRENT SEARCH-WORDLIST  
    IF  \  есть такое, 
        NIP NIP
        >BODY  @ \ выдать адрес структуры мнемоники
    ELSE \ нету, создать
        createMnemo
    THEN
    SWAP \ adr_strMnemo hlp 
    createEncode
    \ adr_strMnemo hlp adr_strEncode
    TUCK .eHlp chain+ \ подключить помощника
    \ adr_strMnemo adr_strEncode
    OVER .mStr @ OVER .eMnemo ! 
    SWAP .mAlt ['] .eAlt extEach  !
    ALSO OperandsHandlers \ подключить обработчики операндов
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

: cliche&mask ( adr u -- mask cliche ) \ из строки adr u вида "0100000101mmmddd"
    \ сделать клише и маску команды
    \ по маске из машинного слова выделяется опознавательный код команды,
    \ а клише служит для сравнения "код=клише"
    2DUP 
    [CHAR] 1 tagMask >R \ R: mask'1'=клише
    [CHAR] 0 tagMask \ mask'0'
    R@ OR R>         \ mask'01' mask'1'
    ;

: chainHelp+ ( adr -- ) \ добавить Это место к помощникам
    encodes @ .eHlp chain+ 
    ;

: fuflo ; \ слово-заглушка

: createOp ( xt tag chain --) \ создать структуру оператора
        \ и добавить его в конец цепочки операндов
        structOp alloc \ xt tag chain adr
        DUP .oLnk ROT chain+ 
        2DUP .oTag ! \ xt tag adr
        SWAP S@ ROT tagMask \ xt adr mask
        OVER .oMask ! \ xt adr
        .oXt ! 
    ;

: fillEncode ( mnem n*[xt,tag] adr2 u2 -- ) \ создать структуру кодировщика команды
    \ по шаблону adr2 u2
    encodes @ >R
    >S
        S@ cliche&mask  
        R@ .eCliche !
        R@ .eMask !
        ['] fuflo R@ .eXt ! \ нету предИсполнителя
        BEGIN ( xt,tag) 
            DUP S@ +listExcepTag inStr? 
            \ потребление операндов
        WHILE  
            R@ .eOps createOp
        REPEAT
    S> 2DROP
    ( mnem)
    R> DROP
    ;

: Encod: ( mnem n*[xt,tag] "encode" --  ) \ строит структуру кодирования 
\ потребляет операнды и мнемонику со стека
    PREVIOUS \ отключить обработчики операндов
    BL WORD COUNT fillEncode \ создать структуру
    \ и включить ее в конец цепочки альтернатив
    \ (mnem)
    
    ;


\ ============== слова помощники/описатели команд ===========================

: helper: ( tag <name> -- ) \ определить помощника
    CREATE ,
    DOES> @ 4BLparse createHlp chainHelp+ 
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

#def #tab> R@ SPACES

: extHlp ( tab adr -- tab adr)
    SWAP >R
        DUP .hTag C@ #tab> tag.
        DUP .hStr @ COUNT TYPE CR
    R> SWAP
    ;

: help. ( .eHlp tab --)
    SWAP
    ['] extHlp extEach 2DROP
    ;

: extAhlp (  tab alt -- tab' alt')
    2DUP .eHlp SWAP help.
    SWAP 4 + SWAP
    ;
: helpAsm ( <name> --) \ показать справку по команде <name>
    CR BL WORD FIND
    IF  >BODY @ ( mnen)
        .mAlt 0 SWAP ['] extAhlp extEach 2DROP ?????????????????
    ELSE DROP
    THEN
    ;

\ ============================================================================
\ слова лишние, но помогающие

: 32bit. ( u -- ) \ печатать 32-битное число в бинарном виде
    8 CELLS BIN[ U.0R ]BIN 
    ;

: extOps ( tab adr -- tab adr) \ показать оператор
    SWAP >R
    #tab>   DUP .oTag  ." tag=   " @ EMIT              CR 
    #tab>   DUP .oMask ." mask=  " @ 32bit.            CR 
    #tab>   DUP .oXt   ." xt=    " @ .HEX              CR 
    R> SWAP
    ;

: shwOps ( adr tab --)
    SWAP ['] extOps extEach 2DROP
    ;

: shwEncode ( adr tab --) \ показать структуру кодировщика команды
    \ с отступом tab
    >R 
    #tab> ." ======================================="  CR 
    #tab> DUP          ." link=  " @ .HEX              CR 
    #tab> DUP .eAlt    ." alt=   " @ .HEX              CR 
    #tab> DUP .eHlp    ." hlp=   " @ .HEX              CR 
    #tab> ." ----------------------------------------" CR 
    #tab> DUP .eCliche ." clishe=" @ 32bit.            CR 
    #tab> DUP .eMask   ." mask=  " @ 32bit.            CR 
    #tab> DUP .eXt     ." preXt= " @ .HEX              CR
    #tab> DUP .eMnemo  ." mnemo= " @ COUNT TYPE  CR
          DUP .eOps R@ shwOps
    #tab> ." ---------------------------------------"  CR 
    .eHlp R@ help.  CR 
    R> DROP
    ;

: shwMnemo ( xt --) \ показать структуру мнемоники
    >BODY @
    DUP .mAlt @ ." alt=   " .HEX CR
    .mStr @ ." mnemo= " COUNT TYPE CR
    ;

: extCmd ( tab adr -- tab' adr')
    SWAP 4 + 2DUP shwEncode SWAP .eAlt 
    ;
: shwCmd ( xt --) \ показать команду полностью
    DUP shwMnemo
    >BODY @ 0 SWAP ( tab alt)
    ['] extCmd extEach 2DROP
    ; \ пример импользования: ' ANDS shwCmd

#def langASM .( loaded) CR



